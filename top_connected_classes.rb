require 'json'

input = ARGV.shift
output = ARGV.shift
omit_self = ARGV.shift
sankey = ARGV.shift

puts "Importing #{input}..."
data = JSON.parse File.read(input)
ids = data.inject({}) { |ac, x| ac[x["id"]] = x; ac }

puts "Calculating connections..."
connections = Hash.new { |h,k| h[k] = Hash.new { |hh,kk| hh[kk] = 0 } }
data.each do |x|
  x["method_ids"].map do |id|
    connections[x["class_name"]][ids[id]["class_name"]] += 1
  end
end

puts "Calculating bidirectional connections..."
table = []
connections.each do |k, v|
  v.each do |kk, vv|
    next if omit_self and kk == k

    r = connections[kk][k]
    unless r == 0
      table << [k, kk, vv, r]
    end
  end
end

puts "Sorting bidirectional connections..."
table.sort! do |a, b|
  primary = b[2] <=> a[2]
  primary == 0 ? b[3] <=> a[3] : primary
end
table = table.first 50

puts "Writing #{output}..."
if sankey
  id = -1
  classes = Hash.new { |h,k| h[k] = (id += 1) }

  table.each do |x|
    classes[x[0]]
    classes[x[1]]
  end

  dict = {}

  nodes = []
  classes.inject(nodes) { |ac, x| ac << { "name" => x.first } }
  dict["nodes"] = nodes

  links = []
  table.inject(links) do |ac, x|
    ac << { "source" => classes[x[0]], "target" => classes[x[1]], "value" => x[2] }
  end
  dict["links"] = links
  File.open output, "w" do |f|
    f.write JSON.generate(dict)
  end
else
  File.open output, "w" do |f|
    id = 0
    f.puts %["id","class1","class2","flow1","flow2"]
    table.each do |x|
      f.puts %[#{id+=1},"#{x[0]}","#{x[1]}",#{x[2]},#{x[3]}]
    end
  end
end
