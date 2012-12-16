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
  # Tests that a version is intact. Version can be in repository or as file.
  # Checks that all files have correct hashes. If recursive is set to true, goes through all dependencies
  # @see test_version
  class VersionTester
    attr_chain :ki_home, :require
    attr_chain :finder, -> { ki_home.finder }
    attr_chain :recursive, -> { true }
    attr_chain :print, -> { false }
    attr_chain :results, -> { Hash.new }

    # Tests that a version is intact
    # * test_version(version) expects a Version parameter
    # @see VersionIterator
    # @see RepositoryFinder
    # @return [bool] returns true if there weren't any problems with the version
    def test_version(root_version, &block)
      all_ok = true
      possible_hashes = KiCommand::CommandRegistry.find!("/hashing")
      # iterates through all versions
      root_version.version_iterator.iterate_versions do |v|
        binaries = v.binaries
        metadata = v.metadata
        metadata.cached_data
        metadata.files.each do |file_hash|
          file_path = file_hash["path"]
          full_path = binaries.path(file_path)
          issue = nil
          if !File.exists?(full_path)
            issue="missing"
          elsif File.size(full_path) != file_hash["size"]
            issue="wrong size"
          elsif !verify_hash(file_hash, full_path, possible_hashes)
            issue="wrong hash"
          end
          if issue
            all_ok = false
            (results[issue]||=[]) << [v, file_path]
            if block
              block.call(issue, v, file_path)
            end
            if print
              puts "#{v.metadata.path}: '#{file_path}' #{issue} '#{v.binaries.path(file_path)}'"
            end
          end
        end
        if !recursive
          break
        end
      end
      all_ok
    end

    def verify_hash(file_hash, full_path, possible_hashes)
      file_hashes = possible_hashes.service_names.select { |name| file_hash.include?(name) }
      checked_hashes = VersionMetadataFile.calculate_hashes(full_path, file_hashes)
      checked_hashes.each_pair do |id, result|
        if file_hash[id] != result
          return false
        end
      end
      true
    end
  end

  # Imports a version to KiHome
  class VersionImporter
    attr_chain :ki_home, :require
    attr_chain :tester, -> { VersionTester.new.recursive(false).print(true) }
    attr_chain :move_files
    attr_chain :create_new_version

    # Imports a version to KiHome
    # * import(file, binary_directory) expects two String parameters defining version file location and directory base for binaries
    def import(*args)
      if args.size == 2
        file, input = args
        source = DirectoryBase.new(input)
        metadata = VersionMetadataFile.new(file)
      else
        raise "Not supported: '#{args.inspect}'"
      end
      test_version(file, input)

      # reads component and version strings from metadata
      if defined? @create_new_version
        component_id = @create_new_version
        version = ki_home.version(component_id)
        if version
          id = version.version_id.split("/").last
          version_number = (Integer(id) + 1).to_s
        else
          version_number = "1"
        end
      else
        metadata.cached_data
        id = metadata.version_id
        version_arr = id.split("/")
        version_number = version_arr.delete_at(-1)
        component_id = version_arr.join("/")
      end

      # creates directories
      info_components = ki_home.repositories.add_item("site").mkdir.components
      binaries = ki_home.packages.add_item("packages/local").mkdir.components
      binary_dest = binaries.add_item(component_id).mkdir.versions.add_version(version_number).mkdir
      metadata_dest = info_components.add_item(component_id).mkdir.versions.add_version(version_number).mkdir

      source_dirs = copy_files_to_repo(component_id, version_number, source, metadata, metadata_dest, binary_dest)
      delete_empty_source_dirs(source, source_dirs)
    end

    def copy_files_to_repo(component_id, version_number, source, metadata, metadata_dest, binary_dest)
      if defined? @create_new_version
        metadata_dest.metadata.cached_data = metadata.cached_data
        metadata_dest.metadata.version_id=File.join(component_id, version_number)
        metadata_dest.metadata.save
        if defined? @move_files
          FileUtils.rm(metadata.path)
        end
      else
        to_repo(metadata.path, metadata_dest.metadata.path)
      end
      source_dirs = []
      metadata.files.each do |file_info|
        file_path = file_info["path"]
        dir = File.dirname(file_path)
        if dir != "."
          source_dirs << dir
          binary_dest.mkdir(dir)
        end
        to_repo(source.path(file_path), binary_dest.path(file_path))
      end
      source_dirs
    end

    def delete_empty_source_dirs(source, source_dirs)
      if defined? @move_files
        expanded_source_dirs = {}
        source_dirs.each do |d|
          dir_entries(d).each do |expanded|
            expanded_source_dirs[expanded] = true
          end
        end
        expanded_source_dirs.keys.each do |dir|
          checked_dir = source.path(dir)
          if Dir.entries(checked_dir) == [".", ".."]
            FileUtils.rmdir(checked_dir)
          end
        end
      end
    end

    # splits dir path in to all components: foo/bar/baz, foo/bar, foo
    def dir_entries(str)
      arr = str.split("/")
      ret = []
      c = arr.size
      while (c > 0)
        ret << File.join(arr[0..c])
        c-=1
      end
      ret
    end

    def to_repo(src, dest)
      if defined? @move_files
        FileUtils.mv(src, dest)
      else
        FileUtils.cp(src, dest)
      end
    end

    def test_version(file, input)
      all_ok = tester.ki_home(ki_home).test_version(Version.create_version(file, input))
      if !all_ok
        raise "Files are not ok!"
      end
    end
  end

  # Exports a version to directory
  # * if test_dependencies set to true, tests the version before exporting
  class VersionExporter
    attr_chain :ki_home, :require
    attr_chain :finder, -> { ki_home.finder }
    attr_chain :test_dependencies
    attr_chain :find_files, -> { FileFinder.new }

    # Exports a version to directory
    def export(version, out)
      ver = finder.version(version)
      if test_dependencies
        test_version(ver)
      end
      files = find_files.version(ver).file_map.sort
      files.each do |file_path, full_path|
        dir = File.dirname(file_path)
        if dir != "."
          FileUtils.mkdir_p File.join(out, dir)
        end
        FileUtils.ln_sf(full_path, File.join(out, file_path))
      end
    end

    def test_version(version)
      tester = VersionTester.new.ki_home(ki_home).finder(finder).recursive(true).print(true)
      all_ok = tester.test_version(version)
      if !all_ok
        raise "Files are not ok!"
      end
    end
  end
end
