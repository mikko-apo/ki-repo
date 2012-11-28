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
# Metadata
# * version_id String
# * build_info Hash. keys: source, tag, commiter. values=Strings
# * filesets Hash. keys: Sorted array of tags. values: List of File info Hash.
#   * File info Hash. keys: path, size, executable, sha-1
# * dependencies List. values: Dependency Hash. keys: dependency_id, path, internal, dependency_operations
# * fileoperations
  class VersionMetadataFile < KiJSONHashFile
    attr_chain :version_id, :require, :accessor => CachedDataAccessor.new
    attr_chain :source, -> { Hash.new }, :accessor => CachedDataAccessor.new
    attr_chain :files, -> { Array.new }, :accessor => CachedDataAccessor.new
    attr_chain :operations, -> { Array.new }, :accessor => CachedDataAccessor.new
    attr_chain :dependencies, -> { Array.new }, :accessor => CachedDataAccessor.new

    def add_file_info(name, size, *args)
      extra = (args.select { |arg| arg.kind_of?(Hash) }.size!(0..1).first or {})
      tags = (args - [extra]).flatten.uniq
      file_hash = {"path" => name, "size" => size}.merge(extra)
      if tags.size > 0
        file_hash["tags"]=tags
      end
      files << file_hash
    end

    # Comma separated list of dependency arguments
    # * dependency parameters can be given in the hash
    # TODO: version_id should be resolved through Version
    def add_dependency(param_str, args={})
      params = param_str.split(",")
      version_id = params.delete_at(0)
      dep_hash = {"version_id" => version_id}.merge(params.to_h("=")).merge(args)
      if dep_hash["internal"]
        dep_hash["internal"]=true
      end
      dep_hash.extend(Dependency)
      dependencies << dep_hash
      dep_hash
    end

    def add_operation(args)
      operations << args
    end

    def VersionMetadataFile.calculate_hashes(full_path, digester_ids)
      digesters = {}
      digester_ids.each do |h|
        digesters[h] = KiCommand::CommandRegistry.find!(File.join("/hashing", h)).digest
      end
      algos = digesters.values
      File.open(full_path, "r") do |io|
        while (!io.eof)
          buf = io.readpartial(1024)
          algos.each do |digester|
            digester.update(buf)
          end
        end
      end
      digesters.each_pair do |h, digester|
        digesters[h]=digester.hexdigest
      end
      digesters
    end

    # Processes all files from source that match patterns and for each file calculates hashes and stores tags based on default_parameters
    def add_files(source, patterns, default_parameters={})
      files_or_dirs = Array.wrap(patterns).map do |pattern|
        Dir.glob(File.join(source, pattern))
      end.flatten

      files = files_or_dirs.map do |file_or_dir|
        if File.directory?(file_or_dir)
          Dir.glob(File.join(file_or_dir, "**/*"))
        else
          file_or_dir
        end
      end.flatten.sort

      files.each do |file|
        add_file(source, file, default_parameters)
      end
      self
    end

    def add_file(root, full_path, parameters)
      stat = File.stat(full_path)
      size = stat.size
      extra = {}
      if stat.executable?
        extra["executable"]=true
      end
      if parameters["tags"] && parameters["tags"].size > 0
        extra["tags"]= parameters["tags"]
      end
      if parameters["hashes"].nil?
        parameters["hashes"]=["sha1"]
      end
      if parameters["hashes"].size > 0
        extra.merge!(VersionMetadataFile.calculate_hashes(full_path, parameters["hashes"]))
      end
      add_file_info(full_path[root.size+1..-1], size, extra)
    end
  end

  module Dependency
    attr_chain :operations, -> { Array.new }, :accessor => AttrChain::HashAccess

    def add_operation(args)
      operations << args
    end
  end

  class VersionStatusFile < KiJSONListFile
    def add_status(key, value, flags={})
      add_item({"key" => key, "value" => value}.merge(flags))
    end

    def matching_statuses(key)
      cached_data.select { |hash| hash["key"].match(key) }
    end
  end
end
