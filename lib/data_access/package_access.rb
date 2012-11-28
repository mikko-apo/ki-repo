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
  # Combines version's information from all different repositories
  # @see Component
  # @see PackageInfo::Version
  # @see PackageInfo::Component
  # @see VersionIterator
  # @see PackageFinder
  # @see FileFinder
  # @see VersionMetadataFile
  # @see VersionStatusFile
  class Version
    attr_chain :component, :require
    attr_chain :name, :require
    attr_chain :version_id, :require
    attr_chain :metadata, -> { find_metadata }
    attr_chain :binaries, -> { find_binaries }
    attr_chain :package_collector, -> { component.package_collector }
    attr_chain :versions, :require
    attr_chain :statuses, -> { collect_statuses }

    # finds first PackageInfo::Version directory for this version that contains binaries
    def find_binaries
      component.components.first.root.packages.each do |package_root|
        binary_dir = package_root.go(version_id)
        if binary_dir.exists?
          return binary_dir
        end
      end
      nil
    end

    # finds first PackageInfo::Version directory that contains metadata
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
  end

  # Combine's component's information from all different repositories
  # @see PackageInfo::Component
  # @see PackageFinder
  class Component
    attr_chain :component_id, :require
    attr_chain :package_collector, :require
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
      package_collector.versions.cache(version_id) do
        info_versions = components.map do |c|
          PackageInfo::Version.new(version_str).version_id(version_id).parent(c)
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
  end
end
