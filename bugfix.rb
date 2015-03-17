# Find bug fixing commits

# Checks for keywords in the commit messages to find references to fixing issues in bug trackers
# Saves bug fixing commits to /data/{project}/bugs.json

require 'json'

PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKIGN_DIR = Dir.pwd

# Rules for indentifying a bug-fix commit based on the
RULES = {
  "junit" => [
    'fix #', 'fixes #', 'fixed #', 'fixes for #', 're #', 'issue #', "for #"
  ],
  "eclipse" => [
    'fix for bug', 'fixed'
  ],
  "storm" => [
    'fix #', 'fixes #', 'fixed #', 'fixes for #', 're #', 'issue #', "for #",
    "storm-",
  ],
  "elasticsearch" => [
    'fix #', 'fixes #', 'fixed #',
  ],
  "spring" => [
    "issue: spr-"
  ]
}

def get_bugfixes_commits project, data
  Dir.chdir data["project_dir"]

  bug_fixes = IO.popen("git log --since='2013-03-01' --before='2014-03-01'"){ |io| io.read }
  .split("commit ")
  .select{ |message| is_bug_fix(message, project) }
  .map { |message| message.match("[0-9a-f]{40}").to_s }
end


def is_bug_fix commit_message, project
  # Rules for labeling commit as a bug fix
  RULES[project].each do |rule|
    if commit_message.downcase.include? rule
      return true
    end
  end
  return false
end


def main
  PROJECTS.each do |project, data|
    bugfix_commits = get_bugfixes_commits project, data

    Dir.chdir WORKIGN_DIR
    File.open("data/#{project}/bugs.json", "w"){ |f|
        f.write bugfix_commits.to_json;
    }
  end
end

main()
