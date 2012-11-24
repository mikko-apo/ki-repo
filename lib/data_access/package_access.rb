module Ki
# List of all directories with information about this version
  class Version
    attr_chain :component, :require
    attr_chain :name, :require
    attr_chain :version_id, :require
    attr_chain :metadata, -> { find_metadata }
    attr_chain :binaries, -> { find_binaries }
    attr_chain :package_collector, -> { component.package_collector }
    attr_chain :versions, :require
    attr_chain :statuses, -> { collect_statuses }

    def find_binaries
      component.components.first.root.packages.each do |package_root|
        binary_dir = package_root.go(version_id)
        if binary_dir.exists?
          return binary_dir
        end
      end
      nil
    end

    def find_metadata
      versions.each do |v|
        m = v.metadata
        if m.exists?
          return m
        end
      end
      nil
    end

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

    def version_iterator
      VersionIterator.new.version(self)
    end

    def find_files(*file_patterns)
      FileFinder.new.version(self).files(file_patterns)
    end
  end

# List of all directories with information about this component
  class Component
    attr_chain :component_id, :require
    attr_chain :package_collector, :require
    attr_chain :versions, -> { find_versions }
    attr_chain :status_info, -> { find_status_info }
    attr_chain :components, :require

    def find_versions
      components.each do |c|
        version_list_file = c.versions
        if version_list_file.exists?
          return version_list_file
        end
      end
      nil
    end

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
