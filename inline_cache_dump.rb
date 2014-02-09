class InlineCacheDump
  Singleton = 1
  Instance = 2
  Unknown = 3

  attr_accessor :id
  attr_reader :map

  def initialize
    @id = 0
    @map = Hash.new { |h,k| h[k] = { id: (self.id += 1), method_ids: [], calls: [] } }
  end

  def module_name_and_type(mod)
    return mod.name, Instance if mod.name
    
    m = mod.inspect.match /\#\<Class:([A-Z][a-z]*)>/
    return m[1], Singleton if m and m[1]

    name = "#{mod.class}_#{mod.object_id}"

    m = mod.inspect.match /\#\<Class:\#\<Class:0x(\d+)>>/
    return name, Singleton if m and m[1]

    return name, Instance
  rescue Object
    return "<unknown module>", Unknown
  end

  def process_method_table(name, type, method_table)
    method_table.each do |n, cc, v|
      begin
        mod = [name, n, type]

        case cc
        when Rubinius::CompiledCode
          cc.call_sites.each do |site|
            case site
            when Rubinius::PolyInlineCache
              site.entries.each do |entry|
                next unless entry

                n, t = module_name_and_type entry.receiver_class
                m = [n, site.name, t]
                map[mod][:method_ids] << map[m][:id]
                map[mod][:calls] << entry.hits
              end
            when Rubinius::MonoInlineCache
              n, t = module_name_and_type site.receiver_class
              m = [n, site.name, t]
              map[mod][:method_ids] << map[m][:id]
              map[mod][:calls] << site.hits
            when Rubinius::CallSite
              map[mod][:id]
            else
              puts "unknown call site: #{site.class}"
            end
          end
        else
          # TODO: other executable kinds
        end
      rescue Object => e
        $stderr.puts e.message, e.backtrace
      end
    end
  end

  def run
    ObjectSpace.each_object(Module) do |obj|
      begin
        name, type = module_name_and_type obj
        process_method_table name, type, obj.method_table

        name, type = module_name_and_type obj.singleton_class
        process_method_table name, type, obj.singleton_class.method_table
      rescue Object => e
        $stderr.puts e.message, e.backtrace
      end
    end

    File.open "inline_cache_#{Process.pid}.json", "w" do |f|
      start = false
      map.each do |k, v|
        start ? f.puts("[") || start = false : f.puts(",")

        f.write %[{"id":#{v[:id]},"class_name":"#{k[0]}","method_name":"#{k[1]}","type":#{k[2]},"method_ids":#{v[:method_ids]},"calls":#{v[:calls]}}]
      end

      f.puts "\n]"
    end
  end
end

at_exit { InlineCacheDump.new.run }
