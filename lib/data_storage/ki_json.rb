# encoding: UTF-8

# Copyright 2012 Mikko Apo
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Ki
  require 'json'

  class KiJSON
    def KiJSON.load_json(path, default=nil)
      if File.exists?(path)
        JSON.parse(IO.read(path))
      else
        default
      end
    end
  end

  class KiJSONFile < DirectoryBase
    attr_chain :json_default, :require

    def load_latest_data(default=json_default)
      KiJSON.load_json(path, default)
    end

    def edit_data(&block)
      data = load_latest_data
      block.call(data)
      File.safe_write(path, JSON.pretty_generate(data))
      data
    end

    def save(data=cached_data)
      File.safe_write(path, JSON.pretty_generate(data))
    end

    def size
      cached_data.size
    end
  end

  class KiJSONListFile < KiJSONFile
    include Enumerable
    attr_chain :json_default, -> { Array.new }
    attr_chain :cached_data, -> { load_latest_data }

    def create_list_item(obj)
      obj
    end

    def add_item(obj)
      edit_data do |list|
        list << obj
      end
      create_list_item(obj)
    end

    def each(&block)
      cached_data.each do |obj|
        block.call(create_list_item(obj))
      end
    end
  end

  class KiJSONHashFile < KiJSONFile
    include Enumerable
    attr_chain :json_default, -> { Hash.new }
    attr_chain :cached_data, -> { load_latest_data }
  end

  class DirectoryWithChildrenInListFile
    def self.add_list_file(obj, clazz, name=nil)
      stripped_class_name = clazz.name.split("::").last
      class_name = clazz.name
      list_class_name = "#{stripped_class_name}ListFile"
      create_id_name = stripped_class_name.gsub(/.[A-Z]/) { |s| "#{s[0]}_#{s[1]}" }.downcase
      if name.nil?
        name = create_id_name
      end
      new_methods = <<METHODS
  class #{list_class_name} < KiJSONListFile
    def create_list_item(#{name}_id)
      i = #{class_name}.new(#{name}_id)
      i.parent(parent)
      i.#{create_id_name}_id(#{name}_id)
      i
    end
  end

  def #{name}s
    #{list_class_name}.new("ki-#{name}s.json").parent(self)
  end

  def #{name}(#{name}_id, #{name}s_list=#{name}s)
    #{name}s_list.each do |c|
      if c.#{name}_id == #{name}_id
        return c
      end
    end
    raise "#{class_name} '\#{#{name}_id}' not found"
  end
METHODS
      obj.class_eval(new_methods, __FILE__, (__LINE__ - new_methods.split("\n").size - 1))
    end
  end

  class CachedDataAccessor
    def get(object, name)
      object.cached_data[name.to_s]
    end

    def set(object, name, value)
      object.cached_data[name.to_s] = value
    end

    def defined?(object, name)
      object.cached_data.include?(name.to_s)
    end
  end

  class HashAccessor
    def get(object, name)
      object[name.to_s]
    end

    def set(object, name, value)
      object[name.to_s] = value
    end

    def defined?(object, name)
      object.include?(name.to_s)
    end
  end
end
