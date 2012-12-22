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

  # Base implementation for json files.
  # * DirectoryBase takes a path argument where file will exist
  # * Classes inheriting this file should implement json_default() to define default data object
  # * cached_data loads data from disk when first accessed and edit_data modifies it
  # * helper methods should access data through cached_data
  class KiJSONFile < DirectoryBase
    attr_chain :cached_data, -> { load_data_from_file }

    # Loads latest data from file path. Does not update cached_data
    def load_data_from_file(default=json_default)
      KiJSONFile.load_json(path, default)
    end

    # Loads data from file path, makes it editable and saves data
    def edit_data(&block)
      @cached_data = load_data_from_file
      block.call(self)
      File.safe_write(path, JSON.pretty_generate(@cached_data))
      @cached_data
    end

    # Saves data to file path. Does not update cached_data
    def save(data=cached_data)
      File.safe_write(path, JSON.pretty_generate(data))
    end

    def size
      cached_data.size
    end

    def KiJSONFile.load_json(path, default=nil)
      if File.exists?(path)
        JSON.parse(IO.read(path))
      else
        default
      end
    end

    def reset_cached_data
      remove_instance_variable(:@cached_data)
    end
  end

  # Base implementation for Json list file
  class KiJSONListFile < KiJSONFile
    include Enumerable
    attr_chain :json_default, -> { Array.new }

    def create_list_item(obj)
      obj
    end

    def add_item(obj)
      edit_data do
        if !@cached_data.include?(obj)
          @cached_data << obj
        end
      end
      create_list_item(obj)
    end

    def each(&block)
      cached_data.each do |obj|
        block.call(create_list_item(obj))
      end
    end
  end

  # Base implementation Json hash file
  #
  # Inheriting classes should implement their values using CachedMapDataAccessor
  #     class VersionMetadataFile < KiJSONHashFile {
  #       attr_chain :source, -> { Hash.new }, :accessor => CachedData
  class KiJSONHashFile < KiJSONFile
    include Enumerable
    attr_chain :json_default, -> { Hash.new }

    class CachedMapDataAccessor
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

    CachedData = CachedMapDataAccessor.new
  end

  # Helper method for creating list files.
  class DirectoryWithChildrenInListFile
    # Helper method for creating list files. When called on a class it extends the class with:
    # * class extending KiJSONListFile which stores list items: class VersionListFile
    # * method to load the file: versions()
    # * method to load a specific item from list file: version(version_id, versions_list=versions)
    def self.add_list_file(obj, clazz, name=nil)
      stripped_class_name = clazz.name.split("::").last
      class_name = clazz.name
      list_class_name = "#{stripped_class_name}ListFile"
      create_id_name = stripped_class_name.gsub(/.[A-Z]/) { |s| "#{s[0]}_#{s[1]}" }.downcase
      if name.nil?
        name = create_id_name
      end
      pluralized_name = "#{name}s".gsub(/ys$/, "ies")
      new_methods = <<METHODS
  class #{list_class_name} < KiJSONListFile
    def create_list_item(#{name}_id)
      i = #{class_name}.new(#{name}_id)
      i.parent(parent)
      i.#{create_id_name}_id(#{name}_id)
      i
    end
  end

  def #{pluralized_name}
      #{list_class_name}.new("ki-#{pluralized_name}.json").parent(self)
  end

  def #{name}(#{name}_id, #{pluralized_name}_list=#{pluralized_name})
    #{pluralized_name}_list.each do |c|
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
end
