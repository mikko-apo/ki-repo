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
  module DirectoryBaseModule
    attr_chain :parent, :require

    def init_from_path(path)
      @path = path
    end

    def name
      File.basename(@path)
    end

    def go(*path)
      if path.empty?
        self
      else
        path = File.join(path).split(File::Separator)
        child = child(path.delete_at(0)).parent(self)
        if path.empty?
          child
        else
          child.go(*path)
        end
      end
    end

    def exists?(*sub_path)
      File.exists?(go(*sub_path).path)
    end

    def mkdir(*path)
      dest = go(*path)
      if !dest.exists?
        FileUtils.mkdir_p(dest.path)
      end
      dest
    end

    def path(*sub_paths)
      new_path = [@path, sub_paths].flatten
      if @parent
        new_path.unshift(@parent.path)
      end
      File.join(new_path)
    end

    def root
      if @parent
        @parent.root
      else
        self
      end
    end

    def root?
      @parent.nil?
    end

    def ki_path(*sub_paths)
      if @parent
        paths = [@parent.ki_path, @path]
      else
        paths = ["/"]
      end
      File.join([paths, sub_paths].flatten)
    end

    def child(name)
      DirectoryBase.new(name)
    end
  end

  class DirectoryBase
    include DirectoryBaseModule

    def initialize(path)
      init_from_path(path)
    end

    def self.find!(path, *locations)
      locations.each do |loc|
        dest = loc.go(path)
        if dest.exists?
          return dest
        end
      end
      raise "Could not find '#{path}' from '#{locations.map { |l| l.path }.join("', '")}'"
    end
  end
end