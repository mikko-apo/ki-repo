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
  #
  #
  class VersionIterator
    attr_chain :version, :require
    attr_chain :dependency
    attr_chain :package_path
    attr_chain :dependency_path
    attr_chain :finder, -> { version.component.finder }
    attr_chain :block
    attr_chain :internals
    attr_chain :exclude_dependencies, -> { [] }, :convert => lambda { |list| Array.wrap(list).map { |s| /#{s}/ } }

    def iterate_versions(&block)
      start_iteration do |version_iterator|
        block.call(version_iterator.version)
        version_iterator.iterate_dependencies
      end
    end

    def start_iteration(v=nil, &block)
      if v
        @version = v
      end
      @block = block
      @internals = true
      block.call(self)
    end

    def iterate_dependencies
      version.metadata.dependencies.map do |dep|
        if internals || !dep["internal"]
          dep_v = VersionIterator.new
          dep_v.version = finder.version(dep["version_id"])
          dep_v.dependency = dep
          dep_v.exclude_dependencies.concat(exclude_dependencies).concat(select_dep_rm(dep))
          dep_v.block = block
          if dep["path"] || package_path
            dep_v.package_path = File.join([package_path, dep["path"]].compact)
          end
          if dependency_path || dep["name"]
            dep_v.dependency_path = File.join([dependency_path, dep["name"]].compact)
          end
          if ok_to_iterate_dependency(dep_v)
            [dep, dep_v.version, block.call(dep_v)]
          end
        end
      end.compact
    end

    def select_dep_rm(dep_v)
      ops = dep_v["operations"]
      if ops
        ops.map do |op|
          if op.first == "dep-rm"
            op[1..-1]
          end
        end.compact.flatten
      else
        []
      end
    end

    def ok_to_iterate_dependency(dep_v)
      !(exclude_dependencies.size > 0 && (exclude_dependencies.any_matches?(dep_v.version.version_id) || dep_v.dependency_path && exclude_dependencies.any_matches?(dep_v.dependency_path)))
    end
  end

  class FileFinder < VersionIterator
    attr_chain :files, -> { [] }, :convert => lambda { |list| Array.wrap(list).map { |s| FileRegexp.matcher(s) } }
    attr_chain :exclude_files, -> { [] }, :convert => lambda { |list| Array.wrap(list).map { |s| FileRegexp.matcher(s) } }
    attr_chain :tags, -> { [] }, :convert => lambda { |list| Array.wrap(list)}
    attr_chain :exclude_tags, -> { [] }, :convert => lambda { |list| Array.wrap(list)}

    def file_map
      start_iteration do |ver_iterator|
        ret = {}
        ver_iterator.iterate_dependencies.each do |dependency, version, file_map|
          file_operations(file_map, dependency)
          ret.merge!(file_map)
        end
        ver = ver_iterator.version
        binaries = ver.binaries
        metadata = ver.metadata
        # TODO: file operations should be applied to the files before the files are filtered
        metadata.files.each do |file|
          if binaries.nil?
            raise "Could not find binaries directory for '#{ver.version_id}'"
          end
          path = file["path"]
          file_path = File.join([ver_iterator.package_path, path].compact)
          if ok_to_add_file(file, file_path)
            ret[file_path]=binaries.path(path)
          end
        end
        file_operations(ret, metadata.cached_data)
        ret
      end
    end

    def file_list
      file_map.values
    end

    # Modifies
    def file_operations(file_map, dependency)
      operations = dependency["operations"]
      if operations
        VersionFileOperations.new.edit_file_map(file_map, operations)
      end
    end

    # File is added to the list if
    # - files pattern list is empty (select all files) or file path matches any files pattern
    # - it does not match any file exclude patterns
    # - tags selection list is empty or file has any tags from tags selection list
    # - no tags match tags from tags exclusion list
    def ok_to_add_file(file, file_path)
      file_tags = file["tags"] || []
      (files.size == 0 || files.any_matches?(file_path)) &&
          !exclude_files.any_matches?(file_path) &&
          (tags.size == 0 || (cross_any_matches?(file_tags, tags)) &&
              !cross_any_matches?(file_tags, exclude_tags))
    end

    def cross_any_matches?(arr, dest_arr)
      arr.each do |i|
        if dest_arr.any_matches?(i)
          return true
        end
      end
      false
    end
  end
end