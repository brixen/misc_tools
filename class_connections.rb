require 'json'

def sum(a)
  a.inject(0) { |s, i| s + i }
end

input = ARGV.shift
output = ARGV.shift

puts "Importing #{input}..."
data = JSON.parse File.read(input)
ids = data.inject({}) { |ac, x| ac[x["id"]] = x; ac }

puts "Calculating connections..."
connections = Hash.new { |h,k| h[k] = Hash.new { |hh,kk| hh[kk] = 0 } }
data.each do |x|
  x["method_ids"].map do |id|
    next if ids[id]["class_name"] == x["class_name"]
    connections[x["class_name"]][ids[id]["class_name"]] += 1
  end
end

puts "Generating connections table..."
h = Hash.new { |h,k| h[k] = 0 }
calls = data.inject(h) { |ac, x| ac[x["class_name"]] += sum(x["calls"]); ac }

table = []
connections.each do |k, v|
  next if k.start_with? "<" or k.start_with? "Class_"
  v.each do |kk, vv|
    next if kk.start_with? "<" or kk.start_with? "Class_"
    table << [k, calls[k], kk]
  end
end

puts "Sorting table..."
table.sort! do |a, b|
  x = a[0] <=> b[0]
  next x unless x == 0
  x = a[2] <=> b[2]
  next x unless x == 0
  b[1] <=> a[1]
end

puts "Writing #{output}..."
File.open output, "w" do |f|
  id = 0
  f.puts %["id","class1","calls","class2"]
  table.each do |x|
    f.puts %[#{id+=1},"#{x[0]}","#{x[1]}",#{x[2]}]
  end
end
