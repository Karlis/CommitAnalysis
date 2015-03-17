# Extend the graph with labels

# Collect all commit label information and add it to the graph
# Form graph into information about each commit to be used in R analysis

require "json"
require "pp"

#Project definitions
PROJECTS = JSON.parse(File.read("data/projects.json"))
WORKING_DIR = Dir.pwd

def getBugFixCommits project, data
  return File.read("data/#{project}/fixing_info").split("\r\n") + JSON.parse(File.read("data/#{project}/bugs.json"))
end

def getChurnCommits project, data
  return JSON.parse(File.read("data/#{project}/churn.json"))
end

def getarchitectureCommits project, data
  return JSON.parse(File.read("data/#{project}/architecture.json"))
end

def getInduceCommits project, data
  # return File.readlines("data/#{project}/inducing.json")
  return File.readlines("data/#{project}/inducing.json").select {|commit| commit.include? "true"}
  .map{|line| line.split(",").first}
end

def createSubGraphs project, data
  graphlo = JSON.parse(File.read("data/#{project}/graph.json"))

  bugFixCommits = getBugFixCommits(project, data).uniq.compact
  churnCommits = getChurnCommits project, data
  architectureCommits = getarchitectureCommits project, data
  induceCommits = getInduceCommits project, data
  timestamp = JSON.parse(File.read("data/#{project}/timestamp.json"))


  graph = {}
  # Fix graph structure
  graphlo.each do |commit, commitData|
    commit = commit.chomp
    graph[commit] = {
      "files" => commitData,
      "type" => ["nodes"],
      "hash" => commit,
      "timestamp" => timestamp[commit],
      "links" => {
        "past" => [],
        "next" => []
      }
    }

    commitData.each do |file, fileInfo|
      graph[commit]["links"]["past"] << fileInfo["pastStrong"]
      graph[commit]["links"]["next"] << fileInfo["nextStrong"]
    end

    graph[commit]["links"]["past"] = graph[commit]["links"]["past"].uniq.compact
    graph[commit]["links"]["next"] = graph[commit]["links"]["next"].uniq.compact
  end


  bugFixCommits.each { |commit| graph[commit]["type"] << "bug" if graph[commit] }
  churnCommits.each { |commit| graph[commit]["type"] << "churn" if graph[commit] }
  architectureCommits.each { |commit| graph[commit]["type"] << "arch"  if graph[commit] }
  induceCommits.each { |commit| graph[commit]["type"] << "induce"  if graph[commit] }

  # create descriptive analysis of subgraphs
  graph.each do |commit, commitData|

    # 1st step
    pastStats = commitData["links"]["past"].map { |commit_hash| graph[commit_hash]["type"] }.flatten.compact
    nextStats = commitData["links"]["next"].map { |commit_hash| graph[commit_hash]["type"] }.flatten.compact


    graph[commit]["1stats"] = {
      "past" => pastStats.each_with_object(Hash.new(0)) { |type,counts| counts[type] += 1 },
      "next" => nextStats.each_with_object(Hash.new(0)) { |type,counts| counts[type] += 1 }
    }
    graph[commit]["1stats"] = normalizeGraphStats graph[commit]["1stats"]

    # 2nd step
    commitData["links"]["past"].each do |commit_hash|
      pastStats += graph[commit_hash]["links"]["past"].map { |commit_hash| graph[commit_hash]["type"] }.flatten
    end

    commitData["links"]["next"].each do |commit_hash|
      nextStats += graph[commit_hash]["links"]["next"].map { |commit_hash| graph[commit_hash]["type"] }.flatten
    end

    graph[commit]["stats"] = {
      "past" => pastStats.each_with_object(Hash.new(0)) { |type,counts| counts[type] += 1 },
      "next" => nextStats.each_with_object(Hash.new(0)) { |type,counts| counts[type] += 1 }
    }

    graph[commit]["stats"] = normalizeGraphStats graph[commit]["stats"]
  end

  return graph
end

def normalizeGraphStats graphStats
  graphStats["normalized"] = {"past" => {}, "next" => {} }

  graphStats["past"].each do |type, value|
    graphStats["normalized"]["past"][type] = (value.to_f / graphStats["past"]["nodes"])
  end

  graphStats["next"].each do |type, value|
    graphStats["normalized"]["next"][type] = (value.to_f / graphStats["next"]["nodes"])
  end

  return graphStats
end

def getJumpStats jumpLinks
    jumpStats = {}
    jumpStats["CC"] = jumpLinks.select{ |item| item["type"].include? "churn" and item["typeTo"].include? "churn" }.length
    jumpStats["CA"] = jumpLinks.select{ |item| item["type"].include? "churn" and item["typeTo"].include? "arch" }.length
    jumpStats["AC"] = jumpLinks.select{ |item| item["type"].include? "arch" and item["typeTo"].include? "churn" }.length
    jumpStats["AA"] = jumpLinks.select{ |item| item["type"].include? "arch" and item["typeTo"].include? "arch" }.length
    jumpStats
end


def findClosestbyType node_hash, graph#, type, direction
  direction = "past"
  type = "induce"
  node = graph[node_hash]

  closestNodes = node["links"][direction].select { |hash|
    graph[hash]["type"].include? type
  }

  if closestNodes.length > 1
    minNode = node
    closestNodes.each {|hash|
      minNode = graph[hash] if graph[hash]["timestamp"] < minNode["timestamp"]
    }
    closestNodes = [ minNode["hash"] ]
  end

  if closestNodes.empty? and !node["links"][direction].empty?
    node["links"][direction].each do |hash|
      return findClosestbyType hash, graph
    end
  else
    return closestNodes
  end
end


def colorNode hash, graph
  color = "white"
  shape = "circle"
  type = graph[hash]["type"]
  color = "red" if type.include? "churn"
  color = "blue" if type.include? "arch"
  color = "green" if type.include? "arch" and type.include? "churn"
  shape = "box" if type.include? "bug"
  return "\"#{hash}\" [shape=#{shape} fillcolor=#{color} color=black style=filled];\n"
end


def main
  PROJECTS.each do |project, data|

    graph = createSubGraphs project, data
    induce = graph.select {|commit, value| value["type"].include? "induce"}
    bugFixCommits = graph.select {|commit, commitData| commitData["type"].include? "bug"}

    puts project.upcase
    puts "-----------------"


    # graph.each { |hash,d| puts colorNode hash, graph }


    # Are links <-> both directions?

    # pp graph.select { |c,cd|
    #     # for every commit there shoulb be links to and back
    #     pastlinksback = cd["links"]["past"].select {|hash| graph[hash]["links"]["next"].include? hash }.length
    #     nextlinksback = cd["links"]["next"].select {|hash| graph[hash]["links"]["past"].include? hash }.length
    #     nextlinksback == cd["links"]["next"].length and pastlinksback == cd["links"]["past"].length
    # }.length
    # pp graph.length


    Dir.chdir WORKING_DIR

    # pp graph.select{ |hash, data|
    #   data["type"].include? "induce" and data["type"].include? "arch"
    # }.map{ |h,d| h}



    #  For filtering out large changes with the most bugs
    # pp graph.select{ |hash, data|
    #   data["type"].include? "churn"
    # }.select{ |h,d| d["stats"]["next"]["bug"] > 100}.map {|h,d| h}
    #.map{ |h,d| d["stats"]["next"]["bug"] }.max


    # Statistics on Churn Jump <-> Architecture Jump commit links in the history of BugFix commits
    # ##############################################################################################

    bugFixCommits = graph.select {|commit, commitData| commitData["type"].include? "bug"}
    bugStatsInformation = []

    # ##############################################################################################
    # Time in between large changes to bug inducing commits directly connected.
    # ##############################################################################################


    # I take all the inducing commits that have jumps in their precedence.

    induce = graph.select {|commit, value| value["type"].include? "induce"}

    # I look at just the first step?

    induceTimeInfor = induce.map {|commit, value|
      timestamp = value["timestamp"].to_i

      links = value["links"]["past"].map {|hash|
        node = graph[hash]

        {"commit" => hash, "type" => node["type"], "timediff" => timestamp - node["timestamp"].to_i }
      }

      {"commit" => commit, "links" => links}
    }


    # pp induceTimeInfor
    # exit









    # ##############################################################################################
    # Precedence
    # ##############################################################################################

    puts "CHURN Preceding a ARCH:"
    pp graph.map {|c,cd|
      cd["links"]["past"].select {|hash| graph[hash]["type"].include? "churn" }.length if cd["type"].include? "arch"
    }.compact.reduce(:+)

    puts "ARCH Preceding a CHURN:"
    pp graph.map {|c,cd|
      cd["links"]["past"].select {|hash| graph[hash]["type"].include? "arch" }.length if cd["type"].include? "churn"
    }.compact.reduce(:+)



    puts "Bug <- CHURN Preceding a ARCH:"
    pp graph.map {|c,cd|
      bugs = cd["links"]["next"].select {|hash| graph[hash]["type"].include? "bug" }.length
      cd["links"]["past"].select {|hash| graph[hash]["type"].include? "churn" }.length if cd["type"].include? "arch" and bugs > 0
    }.compact.reduce(:+)

    puts "Bug <- ARCH Preceding a CHURN:"
    pp graph.map {|c,cd|
      bugs = cd["links"]["next"].select {|hash| graph[hash]["type"].include? "bug" }.length
      cd["links"]["past"].select {|hash| graph[hash]["type"].include? "arch" }.length if cd["type"].include? "churn" and bugs > 0
    }.compact.reduce(:+)


    puts "[Bug] <- CHURN Preceding a ARCH:"
    pp graph.map {|c,cd|
      bugs = cd["links"]["next"].select {|hash| graph[hash]["type"].include? "bug" }
      bugs if cd["type"].include? "arch" and bugs.length > 0 and cd["links"]["past"].select {|hash| graph[hash]["type"].include? "churn" }.length > 0
    }.flatten.compact.uniq.length

    puts "[Bug] <- ARCH Preceding a CHURN:"
    pp graph.map {|c,cd|
      bugs = cd["links"]["next"].select {|hash| graph[hash]["type"].include? "bug" }
      bugs if cd["type"].include? "churn" and bugs.length > 0 and cd["links"]["past"].select {|hash| graph[hash]["type"].include? "arch" }.length > 0
    }.flatten.compact.uniq.length





    # ##############################################################################################
    # How many of bug fixing commits are in the future of an inducing commits?
    # ##############################################################################################

    # inducingCommits = graph.select {|commit, commitData| commitData["type"].include? "induce" }
    # pp inducingCommits.map { |key, value|
    #   value["links"]["next"].select { |hash| graph[hash]["type"].include? "bug" }
    # }

    # TODO
    # There are bugs that don't link to inducing commits
    # And inducing commits that don't linke to bugs

    # Why? How many are these and do they link to bugs to the next step?
    # exit




    # ##############################################################################################
    # How many of the closest in time commits to a bug fix are induce (and jumps)
    # ##############################################################################################
    puts "How many of the closest in time commits to a bug fix are induce (and jumps)"
    bugClosestCommit = {}
    bugFixCommits.map { |commit, commitData|
      minNode = commitData

      commitData["links"]["past"].each { |hash|
        node = graph[hash]
        if node["timestamp"] < minNode["timestamp"]
          minNode = node
        end
      }
      {commit => minNode["hash"] }
    }.each { |item| bugClosestCommit.merge!(item) }

    puts "Induce:"
    pp bugClosestCommit.select {|key, value|
      graph[value]["type"].include? "induce"
    }.length

    puts "Jump:"
    pp bugClosestCommit.select {|key, value|
      graph[value]["type"].include? "arch" or graph[value]["type"].include? "churn"
    }.length

    puts "Jumps + Induce:"
    pp bugClosestCommit.select {|key, value|
      graph[value]["type"].include? "arch" or graph[value]["type"].include? "churn"
    }.select {|key, value|
      graph[value]["type"].include? "induce"
    }.length

    # exit

    # ##############################################################################################
    # Find the nearest node with type "Induce"
    # # ##############################################################################################
    # bugFixClosestInduce = bugFixCommits.map { |commit, commitData|
    #   { "bug_hash" => commit, "induce_hash" => (findClosestbyType commit, graph)}
    # }

    # puts "Project: #{project}"
    # puts "Commits: #{graph.length}"
    # puts "Induce : #{graph.select{|k,v| v["type"].include? "induce"}.length}"

    # pp bugFixClosestInduce.select { |item|
    #   item["induce_hash"].include? bugClosestCommit[item["bug_hash"]]
    # }.length



    # pp bugFixClosestInduce
    # pp bugClosestCommit.length


    # exit

    # ##############################################################################################

    bugFixCommits.each {|commit, commitData|
      bugStats = {
        "commit" => commit,
        "Size" => commitData["links"]["past"].map {|h| graph[h]["links"]["past"].length + 1 }.inject(:+),
        "B1st" => 0, "B2nd" => 0,
        "C1st" => 0, "C2nd" => 0,
        "A1st" => 0, "A2nd" => 0,
        "I1st" => 0, "I2nd" => 0,
      }
      bugStats["B1st"] += commitData["links"]["past"].select { |hash| graph[hash]["type"].include? "bug" }.length
      bugStats["B2nd"] += commitData["links"]["past"].map { |hash|
        graph[hash]["links"]["past"]
      }.flatten.uniq.select { |hash|
        graph[hash]["type"].include? "bug"
      }.length

      bugStats["C1st"] += commitData["links"]["past"].select { |hash| graph[hash]["type"].include? "churn" }.length
      bugStats["C2nd"] += commitData["links"]["past"].map { |hash|
        graph[hash]["links"]["past"]
      }.flatten.uniq.select { |hash|
        graph[hash]["type"].include? "churn"
      }.length


      bugStats["A1st"] += commitData["links"]["past"].select { |hash| graph[hash]["type"].include? "arch" }.length
      bugStats["A2nd"] += commitData["links"]["past"].map { |hash|
        graph[hash]["links"]["past"]
      }.flatten.uniq.select { |hash|
        graph[hash]["type"].include? "arch"
      }.length

      bugStats["I1st"] += commitData["links"]["past"].select { |hash| graph[hash]["type"].include? "induce" }.length
      bugStats["I2nd"] += commitData["links"]["past"].map { |hash|
        graph[hash]["links"]["past"]
      }.flatten.uniq.select { |hash|
        graph[hash]["type"].include? "induce"
      }.length

      bugStatsInformation << bugStats
    }

  File.open("data/#{project}/BugsStats.csv", "w") { |io|
      io.puts "Size, Bug, Churn, Arch, Induce, Bug2nd, Churn2nd, Arch2nd, Induce2nd"
      io.puts bugStatsInformation.map { |commitData| [
          commitData["Size"] || 0,
          commitData["B1st"],commitData["C1st"],commitData["A1st"],commitData["I1st"],
          commitData["B2nd"],commitData["C2nd"],commitData["A2nd"],commitData["I2nd"]
        ].join(", ")
      }.join("\n")
    }

####################################################################################################
# Precidence in commit history
####################################################################################################
    jumpLinks = graph.map { |commit, commitData|
      commitData["links"]["past"].map{|hash_linked|
        {"hash" => commit, "link" => hash_linked}
      }
    }.flatten.select { |item|
      graph[item["link"]]["type"].include? "churn" or graph[item["link"]]["type"].include? "arch"
    }.map{|item|
      graph[item["link"]]["links"]["past"].map { |hash|
        {"hash" => item["hash"], "type" => graph[item["link"]]["type"], "typeTo" => graph[hash]["type"]}
      }
    }.flatten.select { |item|
      item["typeTo"].include? "churn" or item["typeTo"].include? "arch"
    }

# pp jumpLinks

    graphStats = graph.map { |commit,commitData|
      {
        "hash" => commit,
        "combinations" => commitData["links"]["past"].map {|hash| graph[hash]["links"]["past"].length}.inject(:+) || 0,
        "size" => commitData["links"]["past"].map {|hash| graph[hash]["links"]["past"].length + 1}.inject(:+) || 0,
        "jumpStats" => getJumpStats( jumpLinks.select { |item| item["hash"] == commit } )
      }
    }

    File.open("data/#{project}/Preceeding.csv", "w") { |io|
      io.puts "Hash, Type, Size, Combinations, CC, CA, AC, AA, cc, ca, ac, aa"
      io.puts graphStats.select { |commitData|
        commitData["combinations"] > 0
      }.map { |commitData| [
          commitData["hash"],
          graph[commitData["hash"]]["type"].join('-'),
          commitData["size"],
          commitData["combinations"],

          commitData["jumpStats"]["CC"],
          commitData["jumpStats"]["CA"],
          commitData["jumpStats"]["AC"],
          commitData["jumpStats"]["AA"],

          commitData["jumpStats"]["CC"] / commitData["combinations"].to_f ,
          commitData["jumpStats"]["CA"] / commitData["combinations"].to_f,
          commitData["jumpStats"]["AC"] / commitData["combinations"].to_f,
          commitData["jumpStats"]["AA"] / commitData["combinations"].to_f

        ].join(", ")
      }.join("\n")
    }




# ###################################################################################################
# SUBGRAPH PRING GRAPH
# ###################################################################################################

    # bugFixGraph = graphStats
    # .select {|commitData|
    #   commitData["jumpStats"]["CA"] +
    #   commitData["jumpStats"]["AC"] +
    #   commitData["jumpStats"]["AA"] > 6
    # }
    # bugFixGraph.each do |data|
    #   commit = data["hash"]
    #   File.open("data/#{project}/BugGraph#{commit}.dot", "w+") { |f|
    #     f.write "digraph{\ngraph [splines=true overlap=false style=filled];\n"

    #     f.write colorNode commit, graph

    #     graph[commit]["links"]["past"].each do |toCommit|
    #       f.write "\"#{toCommit}\" -> \"#{commit}\";\n"
    #       f.write colorNode toCommit, graph

    #       graph[toCommit]["links"]["past"].each do |ndToCommit|
    #         f.write "\"#{ndToCommit}\" -> \"#{toCommit}\";\n"
    #         f.write colorNode ndToCommit, graph
    #       end
    #     end
    #     f.write "}"
    #   }
    #   system("dot -Tpng data/#{project}/BugGraph#{commit}.dot > data/#{project}/BugGraph#{commit}.png")

    # end




####################################################################################################
# ALL DATA
####################################################################################################
    File.open("data/#{project}/data_table.csv", "w") { |io|
      io.puts "type, timestamp, nodes_p, bugs_p, churn_p, arch_p, induce_p, nodes_n, bugs_n, churn_n, arch_n, induce_n, bugs_pn, churn_pn, arch_pn, induce_pn, bugs_nn, churn_nn, arch_nn, induce_nn, nodes_p_1, bugs_p_1, churn_p_1, arch_p_1, induce_p_1, nodes_n_1, bugs_n_1, churn_n_1, arch_n_1, induce_n_1, bugs_pn_1, churn_pn_1, arch_pn_1, induce_pn_1, bugs_nn_1, churn_nn_1, arch_nn_1, induce_nn_1"
      io.puts graph.map { |commit, commitData|
        [
            commitData["type"].join("-"),
            commitData["timestamp"],

            commitData["stats"]["past"]["nodes"] || 0,
            commitData["stats"]["past"]["bug"] || 0,
            commitData["stats"]["past"]["churn"] || 0,
            commitData["stats"]["past"]["arch"] || 0,
            commitData["stats"]["past"]["induce"] || 0,
            commitData["stats"]["next"]["nodes"] || 0,
            commitData["stats"]["next"]["bug"] || 0,
            commitData["stats"]["next"]["churn"] || 0,
            commitData["stats"]["next"]["arch"] || 0,
            commitData["stats"]["next"]["induce"] || 0,

            commitData["stats"]["normalized"]["past"]["bug"] || 0,
            commitData["stats"]["normalized"]["past"]["churn"] || 0,
            commitData["stats"]["normalized"]["past"]["arch"] || 0,
            commitData["stats"]["normalized"]["past"]["induce"] || 0,
            commitData["stats"]["normalized"]["next"]["bug"] || 0,
            commitData["stats"]["normalized"]["next"]["churn"] || 0,
            commitData["stats"]["normalized"]["next"]["arch"] || 0,
            commitData["stats"]["normalized"]["next"]["induce"] || 0,


            commitData["1stats"]["past"]["nodes"] || 0,
            commitData["1stats"]["past"]["bug"] || 0,
            commitData["1stats"]["past"]["churn"] || 0,
            commitData["1stats"]["past"]["arch"] || 0,
            commitData["1stats"]["past"]["induce"] || 0,
            commitData["1stats"]["next"]["nodes"] || 0,
            commitData["1stats"]["next"]["bug"] || 0,
            commitData["1stats"]["next"]["churn"] || 0,
            commitData["1stats"]["next"]["arch"] || 0,
            commitData["1stats"]["next"]["induce"] || 0,

            commitData["1stats"]["normalized"]["past"]["bug"] || 0,
            commitData["1stats"]["normalized"]["past"]["churn"] || 0,
            commitData["1stats"]["normalized"]["past"]["arch"] || 0,
            commitData["1stats"]["normalized"]["past"]["induce"] || 0,
            commitData["1stats"]["normalized"]["next"]["bug"] || 0,
            commitData["1stats"]["normalized"]["next"]["churn"] || 0,
            commitData["1stats"]["normalized"]["next"]["arch"] || 0,
            commitData["1stats"]["normalized"]["next"]["induce"] || 0

      ].join(", ")
    }.join("\n")
  }
  end
end

main()
