# Add Timestamp to the commits

PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKING_DIR = Dir.pwd

require "json"

def gather_timestamp data
  Dir.chdir data["project_dir"]

  # Gather all commits and with their timestamp.
  cmd = "git log --format='%H %at' --since='2013-02-01' --before='2014-04-01'"
  commits = IO.popen(cmd) { |io|
    io.read.split("\n")
  }.map { |line|
    line.split(" ")
  }

  Hash[commits]

end

def main
  PROJECTS.each do |project, data|
    timestamps = gather_timestamp data
    Dir.chdir WORKING_DIR
    File.open("data/#{project}/timestamp.json", "w"){ |f| f.write timestamps.to_json }
  end
end

main()
