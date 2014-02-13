require 'json'

input = ARGV.shift
output = ARGV.shift
omit_self = ARGV.shift

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
File.open output, "w" do |f|
  id = 0
  f.puts %["id","class1","class2","flow1","flow2"]
  table.each do |x|
    f.puts %[#{id+=1},"#{x[0]}","#{x[1]}",#{x[2]},#{x[3]}]
  end
end
