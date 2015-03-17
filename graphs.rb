# Create the commit graph

#

require "json"

PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKING_DIR = Dir.pwd

def create_commit_matrix_by_shared_files project
  Dir.chdir(project["project_dir"])
  system("git checkout master")

  cmd = "git log --since='2013-03-01' --before='2014-03-01' --format=\"%H %at\""
  lines = IO.popen(cmd) {|io| io.read.split("\n") }
    .map {|line|
      hash, timestamp = line.chomp.split(" ")
      {"hash" => hash, "timestamp" => timestamp.to_i}
    }

  commits_hash = {}
  lines.each {|line| commits_hash[line["hash"]] = {"timestamp" => line["timestamp"] } }
  commits = commits_hash.sort_by {|hash, value| value["timestamp"] }.map {|arr| arr[0] }
  commit_order = Hash[commits.map.with_index.to_a]

  co = {}
  commit_order.each do |hash, order|
    co[order] = hash
  end

  files = {}
  graph = {}
  commits.each { |commit|
    files[commit] = get_files_changed_in_commit(commit)
    graph[commit] = {}
  }

  files.each do |commit, commit_files|
    graph[commit] = {}
    commit_files.each do |file|
      graph[commit][file] = {}
      commits_with_file = commits.select{|commit, value| files[commit].include? file}

      time = commits_hash[commit]["timestamp"]
      time_past = time
      time_next = time
      node_next = nil
      node_past = nil


      commits_with_file.each do |com|
        timestamp = commits_hash[com]["timestamp"]

        if timestamp > time # next
          diff = timestamp - time
          if diff < time_next
            time_next = diff
            node_next = com
          end

        elsif timestamp < time # past
          diff = time - timestamp
          if diff < time_past
            time_past = diff
            node_past = com
          end
        end
      end

      graph[commit][file]["past"] = node_past
      graph[commit][file]["next"] = node_next

      if commits_with_file.length > 3
        graph[commit][file]["pastStrong"] = node_past
        graph[commit][file]["nextStrong"] = node_next
      end

    end
  end
  return graph
end

def get_files_changed_in_commit commit
  IO.popen("git diff-tree --no-commit-id --name-only -r #{commit}") { |io| io.read.split("\n") }
end


# def writeGraphDotFile graph, project
#   File.open("data/#{project}/graph.dot", "w+") { |f|
#     f.write "digraph{\ngraph [splines=true overlap=false];\n"

#     graph.each do |commit_hash, files_hash|
#       files_hash.each do |file, data|
#         f.write "\"#{data["past"]}\" -> \"#{commit_hash}\";\n" if !data["past"].nil?
#       end
#     end

#     f.write "}"
#   }
#   # Instead for a link for each file we create a link for each link between two commits
#   update = File.read("data/#{project}/graph.dot").lines.uniq.join("")
#   File.open("data/#{project}/graph_clean.dot", "w+") { |f|
#     f.write update
#   }
# end

def main
  PROJECTS.each do |project, data|

    graph = create_commit_matrix_by_shared_files data

    Dir.chdir WORKING_DIR
    File.open("data/#{project}/graph.json", "w") { |io| io.write graph.to_json }
    # writeGraphDotFile graph, project
  end
end
main()
