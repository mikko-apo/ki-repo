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
    attr_chain :metadata_file, -> { VersionMetadataFile.new("ki-metadata.json") }
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
          if @input_dir.nil?
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
        ["hashes", "tags"].each do |file_param|
          opts.on("--file-#{file_param} #{file_param.upcase}", "File parameter #{file_param}") do |v|
            default_parameters[file_param]= v.split(",").sort
          end
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
    attr_chain :tester, -> { VersionTester.new.recursive(false).print(true) }
    attr_chain :input_dir, -> { Dir.pwd }
    attr_chain :file, :require

    def execute(ctx, args)
      opts.parse(args)
      if @root_version
        tester.ki_home(ctx.ki_home)
        tester_args = [@root_version]
      else
        tester_args = [file, input_dir]
      end
      all_ok = tester.test_version(*tester_args)
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
            input_dir(File.dirname(v))
          end
          file(v)
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Input directory") do |v|
          input_dir(v)
        end
        opts.on("-v", "--version-id VERSION-ID", "Version's id. Tests version from package directory.") do |v|
          @root_version = v
        end
        opts.on("-r", "--recursive", "Tests version's dependencies also.'") do |v|
          tester.recursive = true
        end
      end
    end
  end

  # Imports version and its files to repository
  # @see VersionImporter
  class ImportVersion
    attr_chain :input_dir, -> { Dir.pwd }
    attr_chain :file, :require
    attr_chain :importer, -> { VersionImporter.new }

    def help
      "Test #{opts}"
    end

    def summary
      "Imports version to local package directories"
    end

    def execute(ctx, args)
      opts.parse(args)
      importer.ki_home(ctx.ki_home)
      importer.import(file, input_dir)
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-f", "--file FILE", "Version source file. By default uses file's directory as source for binary files.'") do |v|
          if @input_dir.nil?
            input_dir(File.dirname(v))
          end
          file(v)
        end
        opts.on("-i", "--input-directory INPUT-DIR", "Input directory") do |v|
          input_dir(v)
        end
        opts.on("-t", "--test-recursive", "Tests version's dependencies before importing.'") do |v|
          importer.tester.recursive = true
        end
      end
    end
  end

  # Exports version from repository to target directory
  # @see VersionExporter
  class ExportVersion
    attr_chain :out, -> { Dir.pwd }
    attr_chain :exporter, -> { VersionExporter.new }

    def help
      "Test #{opts}"
    end

    def summary
      "Export version to current directory or selected output directory"
    end

    def execute(ctx, args)
      version = opts.parse(args).size!(1).first
      exporter.ki_home(ctx.ki_home)
      exporter.export(version, out)
    end

    def opts
      OptionParser.new do |opts|
        opts.on("-o", "--output-directory INPUT-DIR", "Input directory") do |v|
          out(v)
        end
        opts.on("-t", "--test", "Test version before export") do |v|
          exporter.test_dependencies=true
        end
      end
    end
  end

  # Sets status for version
  class VersionStatus
    attr_chain :repository, -> { "site" }

    def help
      "Test"
    end

    def summary
      "Add status to version to specified package info location"
    end

    def execute(ctx, args)
      command = args.delete_at(0)
      case command
        when "add"
          version, key, value, *args = args
          flags = args.to_h("=")
          pi = ctx.ki_home.repository(repository)
          pi.version(version).statuses.add_status(key, value, flags)
        else
          raise "Not supported '#{command}'"
      end
    end
  end

  KiCommand.register_cmd("version-build", BuildVersionMetadataFile)
  KiCommand.register_cmd("version-test", TestVersion)
  KiCommand.register_cmd("version-import", ImportVersion)
  KiCommand.register_cmd("version-export", ExportVersion)
  KiCommand.register_cmd("version-status", VersionStatus)
  KiCommand.register("/hashing/sha1", SHA1)
  KiCommand.register("/hashing/sha2", SHA2)
  KiCommand.register("/hashing/md5", MD5)

end