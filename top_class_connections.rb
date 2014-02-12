require 'json'
require 'csv'

def sum(a)
  a.inject(0) { |s, i| s + i }
end

input = ARGV.shift
output = ARGV.shift

puts "Importing #{input}..."
data = JSON.parse File.read(input)
puts "Done"
id = data.size + 1

classes = Hash.new { |h,k| h[k] = 0 }

data.each do |x|
  classes[x["class_name"]] += sum(x["calls"])
end

classes = Hash[*classes.sort { |a, b| b.last <=> a.last }.flatten]

top_classes = data.select { |x| classes.key? x["class_name"] }

methods = Hash.new { |h,k| h[k] = [] }

top_classes.each do |x|
  methods[x["class_name"]] << [sum(x["calls"]), x["method_name"]]
end

methods.each { |k,v| v.sort! { |a, b| b.first <=> a.first }.slice! 10..-1 }

top_methods = top_classes.select do |x|
  v = methods[x["class_name"]]
  v and v.map { |c, m| m}.include? x["method_name"]
end

unknown = Hash.new { |h,k| h[k] = { id: (id+=1), method_name: "unknown" } }

ids = data.inject({}) { |ac, x| ac[x[:id]] = x }

array = []
top_methods.each do |x|
  record = [x["id"], x["class_name"], x["method_name"], x["type"]]

  x["method_ids"].zip(x["calls"]).each do |y|
    array << record + y
  end
end

class_names = top_classes.inject({}) { |ac, x| ac[x["class_name"]] = x }

array.each do |x|
  callee = ids[x[4]]
  next if callee

  if class_names.key? x[1]
    x[4] = unknown[x[i]][:id]
  else
    x[4] = unknown[:Unknown][:id]
  end
end

File.open output, "w" do |f|
  f.puts %["id","class_name","method_name","type","method_id","calls"]
  array.each do |x|
    f.puts %[#{x[0]},"#{x[1]}","#{x[2]}",#{x[3]},#{x[4]}]
  end
end
