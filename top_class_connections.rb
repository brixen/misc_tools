require 'json'

def sum(a)
  a.inject(0) { |s, i| s + i }
end

input = ARGV.shift
output = ARGV.shift

puts "Importing #{input}..."
data = JSON.parse File.read(input)

puts "Normalizing class names..."
data.each do |x|
  i = x["class_name"].index "::"
  x["class_name"].slice! i..-1 if i
end

puts "Summing method calls per class..."
classes = Hash.new { |h,k| h[k] = 0 }
data.each do |x|
  classes[x["class_name"]] += sum(x["calls"])
end

puts "Extracting top 20 classes..."
classes = Hash[*classes.sort { |a, b| b.last <=> a.last }.flatten.first(40)]
top_classes = data.select { |x| classes.key? x["class_name"] }

puts "Extracting top 10 methods per class..."
methods = Hash.new { |h,k| h[k] = Hash.new { |h,k| h[k] = 0 } }
top_classes.each do |x|
  methods[x["class_name"]][x["method_name"]] += sum(x["calls"])
end

methods = methods.inject({}) do |ac, x|
  ac[x.first] = x.last.sort { |a,b| b.last <=> a.last }.first(10).map(&:first)
  ac
end

top_methods = top_classes.select do |x|
  methods[x["class_name"]].include? x["method_name"]
end

puts "Generating final table..."
ids = data.inject({}) { |ac, x| ac[x["id"]] = x; ac }
table = []
top_methods.each do |x|
  mc = x["method_ids"].zip(x["calls"]).sort { |a, b| b.last <=> a.last }.first(5)

  mc.each do |y|
    table << {
      "id" => x["id"],
      "class_name" => x["class_name"],
      "method_name" => x["method_name"],
      "type" => x["type"],
      "method_id" => (ids.key?(y.first) ? y.first : 0),
      "calls" => y.last
    }
  end
end

puts "Sorting table..."
table.sort! do |a, b|
  a_name = "#{a["class_name"]}#{a["method_name"]}"
  b_name = "#{b["class_name"]}#{b["method_name"]}"
  a_name <=> b_name
end

puts "Writing #{output}..."
File.open output, "w" do |f|
  f.puts %["id","class_name","method_name","type","method_id","calls"]
  table.each do |x|
    f.puts %[#{x["id"]},"#{x["class_name"]}","#{x["method_name"]}",#{x["type"]},#{x["method_id"]},#{x["calls"]}]
  end
end
