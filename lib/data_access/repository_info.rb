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

module Ki
  # Combines version's information from all different repositories
  # @see Component
  # @see Repository::Version
  # @see Repository::Component
  # @see VersionIterator
  # @see RepositoryFinder
  # @see FileFinder
  # @see VersionMetadataFile
  # @see VersionStatusFile
  class Version
    attr_chain :component, :require
    attr_chain :name, :require
    attr_chain :version_id, :require
    attr_chain :metadata, -> { find_metadata }
    attr_chain :binaries, -> { find_binaries }
    attr_chain :finder, -> { component.finder }
    attr_chain :versions, :require
    attr_chain :statuses, -> { collect_statuses }

    # finds first Repository::Version directory for this version that contains binaries
    def find_binaries
      all_repository_versions do |binary_dir|
        if binary_dir.exists?
          return binary_dir
        end
      end
    end

    def all_repository_versions(&block)
      component = find_component
      if component.version(version_id)
        finder.all_repositories.each do |package_root|
          if package_root.exists?(version_id)
            cid = Ki::Component.component_from_version(version_id)
            found_component = Ki::Repository::Component.new(cid).component_id(cid).parent(package_root)
            found_version = Ki::Repository::Version.new(Version.version_id_from_version_str(version_id)).version_id(version_id).parent(found_component)
            block.call(found_version)
          end
        end
      else
        raise "Version not available: " + version_id
      end
      nil
    end

    def find_component
      finder.all_repositories.each do |package_root|
        if component = package_root.component(Ki::Component.component_from_version(version_id))
          return component
        end
      end
      nil
    end

    def find_from_all_repository_versions(&block)
      all_repository_versions do |version|
        file = block.call(version)
        if file.exists?
          return file
        end
      end
    end

    def build_logs
      find_from_all_repository_versions do |version|
        version.build_logs
      end
    end

    def build_info
      find_from_all_repository_versions do |version|
        version.build_info
      end
    end

    # finds first Repository::Version directory that contains metadata
    def find_metadata
      versions.each do |v|
        m = v.metadata
        if m.exists?
          return m
        end
      end
      nil
    end

    # collects all statuses related to this version
    def collect_statuses
      ret = []
      versions.each do |v|
        s = v.statuses
        if s.exists?
          v.statuses.each do |status|
            ret << [status["key"], status["value"]]
          end
        end
      end
      ret
    end

    # finds all versions referenced by this version
    def version_iterator
      VersionIterator.new.version(self)
    end

    # finds files from this version (recursive)
    def find_files(*file_patterns)
      FileFinder.new.version(self).files(file_patterns)
    end

    def exists?
      begin
        return metadata || binaries
      rescue Exception => e
      end
      false
    end

    # Initializes a Version and Repository::Version for files non-imported files
    # * works for testing and showing
    def self.create_version(file, binary_directory=nil)
      dir = File.dirname(file)
      if dir == "."
        dir = Dir.pwd
      end
      version = Version.new
      repo_ver = Repository::Version.new(dir)
      repo_ver.metadata = VersionMetadataFile.new(File.basename(file)).parent(repo_ver)
      version.versions=[repo_ver]
      if binary_directory
        version.binaries = DirectoryBase.new(binary_directory)
      end
      version
    end

    def self.version_id_from_version_str(version_str)
      version_str.split("/").delete_at(-1)
    end
  end

  # Combine's component's information from all different repositories
  # @see Repository::Component
  # @see RepositoryFinder
  class Component
    attr_chain :component_id, :require
    # Package collector contains
    attr_chain :finder, :require
    attr_chain :versions, -> { find_versions }
    attr_chain :status_info, -> { find_status_info }
    attr_chain :components, :require

    # Returns version list from first component which has a version list
    def find_versions
      components.each do |c|
        version_list_file = c.versions
        if version_list_file.exists?
          return version_list_file
        end
      end
      nil
    end

    # Returns Version which references all existing version directories
    # @see Version
    def version_by_id(version_str)
      version_id = File.join(component_id, version_str)
      finder.versions.cache(version_id) do
        info_versions = components.map do |c|
          Repository::Version.new(version_str).version_id(version_id).parent(c)
        end
        existing_versions = info_versions.select do |v|
          v.exists?
        end
        Version.new.component(self).version_id(version_id).name(version_str).versions(existing_versions)
      end
    end

    def find_status_info
      ret = {}
      components.each do |c|
        si = c.status_info
        if si.exists?
          ret.merge!(si.cached_data)
        end
      end
      ret
    end

    def Component.component_from_version(str)
      args = str.split("/")
      args.delete_at(-1)
      args.join("/")
    end
  end
end
