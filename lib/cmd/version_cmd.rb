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

  # Builds and updates ki-metada.json file based on parameters and added files
  # @see VersionMetadataFile
  class BuildVersionMetadataFile
    attr_chain :input_dir, -> { Dir.pwd }
    attr_chain :metadata_file, -> { VersionMetadataFile.new("ki-version.json") }
    attr_chain :source_parameters, -> { Hash.new }
    attr_chain :default_parameters, -> { {"hashes" => ["sha1"], "tags" => []} }
    attr_chain :previous_dep, :require => "Define a dependency before -o or --operation"
    attr_chain :shell_command, :require

    def execute(ctx, args)
      # opts.parse parses input parameters and fills in configuration parameters
      files = opts.parse(args)
      if source_parameters.size > 0
        metadata_file.source(source_parameters)
      end
      # adds files to metadata and fills in parameters
      metadata_file.add_files(input_dir, files, default_parameters)
      metadata_file.save
    end

    def help
      "#{shell_command} #{opts}"
    end

    def summary
      "Creates version metadata file. Possible to set source info, dependencies, files and operations."
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-f", "--file FILE", "Version file target") do |v|
          if !defined? @input_dir
            input_dir(File.dirname(v))
          end
          metadata_file.init_from_path(v)
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Input directory") do |v|
          input_dir(v)
        end
        opts.on("-v", "--version-id VERSION-ID", "Version's id") do |v|
          metadata_file.version_id=v
        end
        ["url", "tag-url", "author", "repotype"].each do |source_param|
          opts.on("--source-#{source_param} #{source_param.upcase}", "Build source parameter #{source_param}") do |v|
            source_parameters[source_param]=v
          end
        end
        opts.on("-t", "--tags TAGS", "Tag files with keywords") do |v|
          default_parameters["tags"]= v.split(",").sort
        end
        hash_prefix = "/hashing"
        hashes = KiCommand::CommandRegistry.find(hash_prefix).map { |k, v| k[hash_prefix.size+1..-1] }
        opts.on("--hashes HASHES", "Calculate checksums using defined hash algos. Default: sha1. Available: #{hashes.join(", ")}") do |v|
          default_parameters["hashes"]= v.split(",").sort
        end
        opts.on("-d", "--dependency DEPENDENCY", "Dependency definition my/component/123[,name=AA][,path=aa][,internal]") do |v|
          previous_dep(metadata_file.add_dependency(v))
        end
        opts.on("-o", "--operation OP", "Add operation to previous dependency") do |v|
          previous_dep.add_operation(v.split(" "))
        end
        opts.on("-O", "--version-operation OP", "Add operation to version") do |v|
          metadata_file.add_operation(v.split(" "))
        end
      end
    end
  end

  # Tests version from repository or metadata file
  # @see VersionTester
  class TestVersion
    def execute(ctx, args)
      @tester = VersionTester.new.recursive(false).print(true)
      ver_strs = opts.parse(args)
      if ver_strs.size > 0 || @tester.recursive
        @tester.ki_home(ctx.ki_home)
        versions = ver_strs.map { |v| ctx.ki_home.version(v) }
      else
        versions = []
      end
      if @file
        versions.unshift Version.create_version(@file, @input_dir)
      end
      all_ok = true
      versions.each do |v|
        all_ok = all_ok && @tester.test_version(v)
      end
      if all_ok
        puts "All files ok."
      end
    end

    def help
      "Test #{opts}"
    end

    def summary
      "Tests version's files if they are intact."
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-f", "--file FILE", "Version source file. By default uses file's directory as source for binary files.'") do |v|
          if @input_dir.nil?
            dir = File.dirname(v)
            @input_dir = dir != "." ? dir : Dir.pwd
          end
          @file = v
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Binary file input directory") do |v|
          @input_dir = v
        end
        opts.on("-r", "--recursive", "Tests version's dependencies also.'") do |v|
          @tester.recursive = true
        end
      end
    end
  end

  # Imports version and its files to repository
  # @see VersionImporter
  class ImportVersion
    attr_chain :input_dir, -> { Dir.pwd }
    attr_chain :file, -> { File.join(input_dir, "ki-version.json") }
    attr_chain :importer, -> {}

    def help
      "Test #{opts}"
    end

    def summary
      "Imports version to local package directories"
    end

    def execute(ctx, args)
      @importer = VersionImporter.new
      opts.parse(args)
      @importer.ki_home(ctx.ki_home).import(file, input_dir)
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-f", "--file FILE", "Version source file. By default uses file's directory as source for binary files.'") do |v|
          if !defined? @input_dir
            input_dir(File.dirname(v))
          end
          file(v)
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Input directory") do |v|
          input_dir(v)
        end
        opts.on("-t", "--test-recursive", "Tests version's dependencies before importing.'") do |v|
          @importer.tester.recursive = true
        end
        opts.on("-m", "--move", "Moves files to repository'") do |v|
          @importer.move_files = true
        end
        opts.on("-c", "--create-new-version COMPONENT", "Creates new version number for defined component'") do |c|
          @importer.create_new_version = c
        end
        opts.on("-v", "--version-id VERSION", "Imports version with defined version id'") do |v|
          @importer.specific_version_id = v
        end
      end
    end
  end

  # Exports version from repository to target directory
  # @see VersionExporter
  class ExportVersion
    attr_chain :out, -> { Dir.pwd }

    def help
      "Test #{opts}"
    end

    def summary
      "Export version to current directory or selected output directory"
    end

    def execute(ctx, args)
      @exporter = VersionExporter.new
      file_patterns = opts.parse(args)
      version = file_patterns.delete_at(0)
      @exporter.find_files.files(file_patterns)
      @exporter.ki_home(ctx.ki_home).export(version, out)
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-o", "--output-directory INPUT-DIR", "Input directory") do |v|
          out(v)
        end
        opts.on("--tags TAGS", "Select files with matching tag") do |v|
          @exporter.find_files.tags(v.split(","))
        end
        opts.on("-t", "--test", "Test version before export") do |v|
          @exporter.test_dependencies=true
        end
        opts.on("-c", "--copy", "Exported files are copied instead of linked") do |v|
          @exporter.copy=true
        end
      end
    end
  end

  # Sets status for version
  class VersionStatus
    def help
      "Test"
    end

    def summary
      "Add status to version to specified package info location"
    end

    def execute(ctx, args)
      @repository = "site"
      command = args.delete_at(0)
      case command
        when "add"
          version, key_value, *rest = args
          key, value = key_value.split("=")
          flags = rest.to_h("=")
          repository = ctx.ki_home.repository(@repository)
          repository.version(version).statuses.add_status(key, value, flags)
        when "order"
          component, key, values_str = args
          repository = ctx.ki_home.repository(@repository)
          repository.component(component).status_info.edit_data do |info|
            info.cached_data[key]=values_str.split(",")
          end
        else
          raise "Not supported '#{command}'"
      end
    end
  end

  # Shows information about a version
  class ShowVersion
    def help
      "Test #{opts}"
    end

    def summary
      "Prints information about version or versions"
    end

    def execute(ctx, args)
      finder = ctx.ki_home.finder
      versions = opts.parse(args).map { |v| finder.version(v) }
      if @file
        versions.unshift Version.create_version(@file, @input_dir)
      end
      versions.each do |ver|
        VersionIterator.new.finder(finder).version(ver).iterate_versions do |version|
          metadata = version.metadata
          puts "Version: #{metadata.version_id}"
          if metadata.source.size > 0
            puts "Source: #{map_to_csl(metadata.source)}"
          end
          if metadata.dependencies.size > 0
            puts "Dependencies(#{metadata.dependencies.size}):"
            metadata.dependencies.each do |dep|
              dep_data = dep.dup
              dep_ops = dep_data.delete("operations")
              puts "#{dep_data.delete("version_id")}: #{map_to_csl(dep_data)}"
              if dep_ops && dep_ops.size > 0
                puts "Depedency operations:"
                dep_ops.each do |op|
                  puts op.join(" ")
                end
              end
            end
          end
          if metadata.files.size > 0
            puts "Files(#{metadata.files.size}):"
            metadata.files.each do |file|
              file_data = file.dup
              puts "#{file_data.delete("path")} - size: #{file_data.delete("size")}, #{map_to_csl(file_data)}"
            end
          end
          if metadata.operations.size > 0
            puts "Version operations(#{metadata.operations.size}):"
            metadata.operations.each do |op|
              puts op.join(" ")
            end
          end
          if @dirs
            puts "Version directories: #{version.versions.map { |v| v.path }.join(", ")}"
          end
          if !@recursive
            break
          end
        end
      end
    end

    def map_to_csl(map)
      map.sort.map { |k, v| "#{k}=#{Array.wrap(v).join(",")}" }.join(", ")
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-r", "--recursive", "Shows version's dependencies.'") do |v|
          @recursive = true
        end
        opts.on("-d", "--dirs", "Shows version's directories.'") do |v|
          @dirs = true
        end
        opts.on("-f", "--file FILE", "Version source file. By default uses file's directory as source for binary files.'") do |v|
          if @input_dir.nil?
            dir = File.dirname(v)
            @input_dir = dir != "." ? dir : Dir.pwd
          end
          @file = v
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Binary file input directory") do |v|
          @input_dir = v
        end
      end
    end
  end

  # Sets status for version
  class VersionSearch
    def help
      "Test"
    end

    def summary
      "Searches for versions and components"
    end

    def execute(ctx, args)
      finder = ctx.ki_home.finder
      args.each do |arg|
        version = finder.version(arg)
        if version
          puts version.version_id
        else
          matcher = FileRegexp.matcher(arg)
          found_components = finder.components.keys.select { |name| matcher.match(name) }
          if found_components.size > 0
            puts "Found components(#{found_components.size}):"
            puts found_components.join("\n")
          else
            puts "'#{arg}' does not match versions or components"
          end
        end
      end
    end
  end

  KiCommand.register_cmd("version-build", BuildVersionMetadataFile)
  KiCommand.register_cmd("version-test", TestVersion)
  KiCommand.register_cmd("version-import", ImportVersion)
  KiCommand.register_cmd("version-export", ExportVersion)
  KiCommand.register_cmd("version-status", VersionStatus)
  KiCommand.register_cmd("version-show", ShowVersion)
  KiCommand.register_cmd("version-search", VersionSearch)
  KiCommand.register("/hashing/sha1", SHA1)
  KiCommand.register("/hashing/sha2", SHA2)
  KiCommand.register("/hashing/md5", MD5)

end