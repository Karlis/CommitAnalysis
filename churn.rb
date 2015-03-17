# Measures the commit size

# Retrieves the commit size using regression line
# Filters out jumps and saves them to /data/{project}/churn.json

require 'json'
require 'descriptive_statistics'

PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKING_DIR = Dir.pwd

def get_commit_with_size project
  # GET a list of commits and their size
  Encoding.default_external = Encoding::UTF_8
  Dir.chdir(project["project_dir"])
  system("git checkout master")

  # Get a list of commits
  commits = IO.popen("git log --since='2013-03-01' --before='2014-03-01' --format=\"%H\"") {|io| io.readlines}
  commits_stats = commits.map {|commit| parse_commit_size(commit.chomp) }.reduce Hash.new, :merge
end

def parse_commit_size commit
  stats = IO.popen("git show " + commit + " --numstat") {|io| io.readlines }
                        .select {|line| Integer( line.split(" ")[0] ) rescue false}
                        .map { |line|
    stats = line.split(" ")
    stats[0] = Integer(stats[0]) rescue nil
    stats[1] = Integer(stats[1]) rescue nil
    stats
  }
  .select { |arr| arr[0] != nil and arr[1] != nil }
  .reduce({"added" => 0 , "removed" => 0, "java" => {"added" => 0, "removed" => 0}
    }) { |result, line|
      result["added"] += line[0]
      result["removed"] += line[1]
      if "java" == line[2].split(".").last
        result["java"]["added"] += line[0]
        result["java"]["removed"] += line[1]
      end
      result
  }

  {commit => stats}
end

def filter_jumps commits, project_data
  # Calculate commit size
  commits.each do |key, value|
    commits[key]['size'] = calculate_commit_size(value, project_data)
    commits[key]['java']['size'] = calculate_commit_size(value["java"], project_data)
  end

  commit_size_array = commits.map {|key, value| value['size'] }
  commit_java_size_array = commits.map {|key, value| value['java']['size'] }

  jump_size_limit = commit_size_array.mean + commit_size_array.standard_deviation
  jump_java_size_limit = commit_java_size_array.mean + commit_java_size_array.standard_deviation

  commit_jumps = commits.select { |key, value| value['size'] > jump_size_limit }
  commits_java_jumps  = commits.select { |key, value| value['java']['size'] > jump_java_size_limit }
  return commit_jumps, commits_java_jumps
end

def calculate_commit_size commit_data, project_data
  # Linear regresion based on Hofmann and Riehle
  size = project_data['churn']['added_coef'] * commit_data['added'] + project_data['churn']['removed_coef'] * commit_data['removed'] + project_data['churn']['adjusment_coef']
  return size
end

def main
  PROJECTS.each do |project, data|

    commits = get_commit_with_size(data)
    jumps, java_jumps = filter_jumps(commits, data)

    Dir.chdir WORKING_DIR

    # File.open("data/#{project}/all_commit_stats.txt", "w"){ |f|
    #   f.write "# #{project} commits \n"
    #   commits.each do |commit, stats|
    #     f.write "#{commit} a:#{stats['added']} d:#{stats['removed']}"
    #     f.write " | java-a: #{stats['java']['added']} java-d: #{stats['java']['removed']}"
    #     f.write "\n"
    #   end
    #   f.write "\n"
    # }

    File.open("data/#{project}/churn.json", "w"){ |f|
      f.write java_jumps.map {|commit, data| commit}.to_json
    }

    # File.open("data/#{project}/churn_jumps_java.txt", "w"){ |f|
    #   java_jumps.each do |jump, stats|
    #     f.write "#{jump} a:#{stats['java']['added']} d:#{stats['java']['removed']}\n"
    #   end
    # }

  end
end



main()
