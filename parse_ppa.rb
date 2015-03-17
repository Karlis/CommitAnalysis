# Parse PPA output

# Genereate a graph from class dependency links
# Hash class links into class node label
# Calculate similarity and relative structure
# Save to /Users/klukstins/dev/University/thesis/commit_values.txt


require 'json'
$dictionay = {}
COMMIT_VALUES_FILE = "/Users/klukstins/dev/University/thesis/commit_values.txt"

module NHK
  # ROTATE BITS RIGHT
  def rbr hash, count
    # XXX the 64 is the bit length. For now hardcoded
    #   If changed also the "0xFFFFFFFFFFFFFFFF" has to be adjusted to be a larger(longer) bit number
    (hash >> count) | (hash << (64 - count)) & 0xFFFFFFFFFFFFFFFF
  end

  # Perform NHK method hashing
  def hash_label label, array_neighbours_labels
    # puts "\n\n #{label}, #{array_neighbours_labels}"
    label.to_i ^ array_neighbours_labels.reduce(:^)
  end
end
# NHK method
class NHKNode
  attr_accessor :label, :neighbours
  include NHK

  def initialize node_name
    @label = node_name
    @neighbours = {}
  end

  def add_neighbour neighbour
    if @neighbours[neighbour]
      @neighbours[neighbour] += 1
    else
      @neighbours[neighbour] = 1
    end
  end

  def neighbour_encoded_label
    labels = get_neighbours_labels
    node_label = rbr(@label, 1)
    # node_label = @label

    return node_label if labels.empty?
    encoded_label = hash_label(node_label, labels)
  end

  def get_neighbours_labels
    neighbours_labels = []
    @neighbours.each do |neighbour, times|
      neighbours_labels << neighbour.label
    end
    return neighbours_labels
  end
end

def get_commit_structural_distance commit

  graph_alfa = create_graph(commit["alfa"])
  graph_alfa_x = create_graph(commit["alfa_x"])
  graph_omega_x = create_graph(commit["omega_x"])
  graph_omega = create_graph(commit["omega"])
  #Encode neighbours
  labels = encode_neighbours(graph_alfa, graph_alfa_x, graph_omega, graph_omega_x)

  distance_alfa = get_structural_distance( labels["alpha"] )
  distance_omega = get_structural_distance( labels["omega"] )

  return distance_alfa, distance_omega
end

def get_structural_distance labels

  # Combine both arrays of encoded labels
  # Compare how similar are the arrays with Jacardi index

  all = labels["a"] + labels["a_x"]
  unique_length = all.uniq.length
  intersection = all.length - unique_length

  return 1 if intersection === unique_length # both are 0
  return intersection / unique_length.to_f
end

def encode_neighbours a, a_x, o_x, o
  # Take all of the graphs and encode the neighbours into the node

  labels = {"alpha" => {"a" => [], "a_x" => []}, "omega" => {"a" => [], "a_x" => []}}

  a.each do |key, value|
    labels["alpha"]["a"] << value.neighbour_encoded_label
  end

  a_x.each do |key, value|
    labels["alpha"]["a_x"] << value.neighbour_encoded_label
  end

  o.each do |key, value|
    labels["omega"]["a"] << value.neighbour_encoded_label
  end

  o_x.each do |key, value|
    labels["omega"]["a_x"] << value.neighbour_encoded_label
  end

  return labels
end

def create_graph ppa_string
  nodes = {}
  ppa_string.each_line do |line|
    classNode, classNodeLinked, link = line.split(",", 3)

    if !nodes[classNode]
      nodes[classNode] = NHKNode.new( new_encode_label(classNode) )
    end

    if !nodes[classNodeLinked]
      nodes[classNodeLinked] = NHKNode.new( new_encode_label(classNodeLinked) )
    end

    nodes[classNode].add_neighbour nodes[classNodeLinked]
  end
  return nodes
end

def new_encode_label label

  if !$dictionay.keys.include? label
    encode_bits = 30
    new_bit_label = 0

    loop do  # loop until we have generated a unique bit_label
      new_bit_label = rand( 1<<encode_bits )
      if !$dictionay.values.include? new_bit_label
        $dictionay[label] = new_bit_label
        break
      end
    end
  end
  return $dictionay[label]
end

# MAIN ppa_output
# Takes the eclipse PPA output and measures realtive structure for each of the commits.
def main ppa_output_file

  commit = JSON.parse(File.read(ppa_output_file))

  alfa, omega = get_commit_structural_distance(commit)
  alfa = 1 - alfa
  omega = 1 - omega

  data = {}
  data[commit["commit"]] = {"a" => alfa, "o" => omega, "rd" => (alfa - omega) / (alfa + omega)}

  File.open(COMMIT_VALUES_FILE, "a") {|f| f.write data.to_json.force_encoding(Encoding::UTF_8) + ",/n" }
end

main(ARGV[0])
