module Ki
  module KiEnumerable
    def size!(*args)
      args.each do |valid_size|
        if valid_size.kind_of?(Range)
          if valid_size.include?(size)
            return self
          end
        elsif valid_size.respond_to?(:to_i)
          if valid_size.to_i == size
            return self
          end
        else
          raise "'#{valid_size.inspect}' not supported, needs to be either Range or have .to_i method"
        end
      end
      raise "size #{size} does not match '#{args.map { |s| s.to_s }.join("', '")}'"
    end

    def any_matches?(value)
      each do |pattern|
        if value.match(pattern)
          return pattern
        end
      end
      false
    end

    def find_first(count=1, &block)
      ret = []
      each do |item|
        if block.nil? || block.call(item)
          ret << item
          if ret.size == count
            break
          end
        end
      end
      if count==1
        ret.at(0)
      else
        ret
      end
    end

    def to_h(separator=nil, &block)
      ret = {}
      each do |item|
        if separator
          key, *values = item.split(separator)
          if values.size > 0 || item.include?(separator)
            ret[key]=values.join(separator)
          else
            ret[key]=true
          end
        elsif block
          key, value = block.call(item)
          ret[key]=value
        end
      end
      ret
    end

  end
end

class Array
  include Ki::KiEnumerable

  def Array.wrap(maybe_arr)
    if maybe_arr.kind_of?(Array)
      maybe_arr
    else
      [maybe_arr]
    end
  end
end

module Enumerable
  include Ki::KiEnumerable
end

require 'fileutils'
class File
  def File.safe_write(dest, txt=nil, &block)
    tmp = dest + "-" + rand(9999).to_s
    File.open(tmp, "w") do |file|
      if block
        block.call(file)
      elsif txt
        file.write(txt)
      end
    end
    FileUtils.mv(tmp, dest)
  end
end

class Hash
  original_get = self.instance_method(:[])

  define_method(:[]) do |key, default=nil|
    value = original_get.bind(self).call(key)
    if value || include?(key)
      value
    else
      default
    end
  end

  def require(key)
    if !include?(key)
      raise "'#{key}' is not defined!"
    end
    self[key]
  end
end
