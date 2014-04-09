# encoding: UTF-8

# Copyright 2012-2013 Mikko Apo
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

require 'lockfile'

module Ki

  class DirectoryBase
    attr_chain :parent, :require

    def initialize(path)
      init_from_path(path)
    end

    def self.find!(path, *locations)
      locations.each do |loc|
        dest = loc.go(path)
        if dest.exist?
          return dest
        end
      end
      raise "Could not find '#{path}' from '#{locations.map { |l| l.path }.join("', '")}'"
    end


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

    def exist?(*sub_path)
      File.exist?(go(*sub_path).path)
    end

    def mkdir(*path)
      dest = go(*path)
      if !dest.exist?
        FileUtils.mkdir_p(dest.path)
      end
      dest
    end

    def path(*sub_paths)
      new_path = [@path, sub_paths].flatten
      if defined? @parent
        new_path.unshift(@parent.path)
      end
      File.join(new_path)
    end

    def root
      if defined? @parent
        @parent.root
      else
        self
      end
    end

    def root?
      !defined? @parent
    end

    def ki_path(*sub_paths)
      if defined? @parent
        paths = [@parent.ki_path, @path]
      else
        paths = ["/"]
      end
      File.join([paths, sub_paths].flatten)
    end

    def child(name)
      DirectoryBase.new(name)
    end

    def empty?(*sub_path)
      Dir.entries(go(*sub_path).path).size == 2
    end

    def lock(&block)
      p = path
      dir_path = File.dirname(p)
      if !File.exist?(dir_path)
        FileUtils.mkdir(dir_path)
      end
      lockfile = Lockfile.new(p + ".ki-lock")
      begin
        lockfile.lock
        return block.call
      ensure
        lockfile.unlock
      end
    end
  end
end