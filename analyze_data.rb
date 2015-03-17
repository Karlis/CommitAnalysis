# Analysis of the PPA results saved in /data/{project}/structure.json

# Gets the list of commits and their relative structure measure to calculate
# the relative change in structure
# Saves the jumps to /data/{project}/structure




require 'json'

PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKING_DIR = Dir.pwd

module Enumerable
  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def mean
    self.sum/self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end
end

def getStructureJumps project, data
    real_commits = JSON.parse(File.read("data/#{project}/structure.json"))

    # Array of hashes to a single hash
    commits = {}
    real_commits.each { |hash| commits.merge!(hash) }

    prevValue = commits.first[1]["rd"]
    commits.each do |key, value|
        commits[key]["relative"] = (value["rd"] - prevValue).abs
        prevValue = value["rd"]
    end

    graph.each do |hash|
      if commits[hash].nil?
        commits[hash] = {"relative" => 0}
      end
    end

    data = commits.map {|commit, data| data["relative"]}
    burst_limit = data.mean + data.standard_deviation

    return commits.select {|commit, data| data["relative"] > burst_limit}
end


def fixHashLength commits, data

  Dir.chdir data["project_dir"]
  new_commits = commits.map {|commit, commitData|
    IO.popen("git show #{commit} --format=\"%H\"") {|io| io.readlines.first.chomp }
  }
  Dir.chdir WORKING_DIR

  return new_commits
end


def main

  PROJECTS.each do |project, data|

    bursts = getStructureJumps project, data

    #Fix the hash length
    bursts = fixHashLength bursts, data

    File.open("data/#{project}/architecture.json", "w") {|io|
      io.write bursts.to_json
    }
  end
end

main()
