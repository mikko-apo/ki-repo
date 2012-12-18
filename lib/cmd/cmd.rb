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

require 'optparse'

module Ki

# Common launcher for all Ki commands
# * all command classes can register themselves using the register_cmd method
  class KiCommand
    # Shared command registry
    CommandRegistry = ServiceRegistry.new
    CommandPrefix = "/commands/"

    # Shared KiHome for commands
    attr_chain :ki_home, -> { KiHome.new(ENV["KIHOME"] || File.expand_path(File.join("~", "ki"))).mkdir }

    attr_chain :user_pref, -> { UserPrefFile.new.parent(ki_home) }

    # Command classes are registered using this method
    def self.register_cmd(name, clazz)
      register(CommandPrefix + name, clazz)
    end

    def self.register(name, clazz)
      CommandRegistry.register(name, clazz)
    end

    def load_scripts
      # load all script files defined in UserPrefFile uses
      uses = @use.empty? ? user_pref.uses : @use
      uses.each do |use_str|
        ver, tags_str = use_str.split(":")
        tags = tags_str ? tags_str.split(",") : "ki-cmd"
        version = ki_home.version(ver)
        version.find_files.tags(tags).file_list.each do |full_path|
          load full_path
        end
      end
    end

    def find_cmd(name)
      prefixed_command_names = user_pref.prefixes.map { |p| [p+name, p+"-"+name] }.flatten

      # Finds all matching combinations of prefix+name -> there should be exactly one
      all_commands = {}
      CommandRegistry.find("/commands").each { |(command, clazz)| all_commands[command[CommandPrefix.size..-1]]=clazz }
      prefixed_command_names.unshift(name)
      found_command_names = prefixed_command_names.select { |p| all_commands.key?(p) }

      # abort if found_command_names.size != 1
      if found_command_names.size > 1
        raise "Multiple commands match: " + found_command_names.join(", ")
      elsif found_command_names.size == 0
        raise "No commands match: " + prefixed_command_names.join(", ")
      end
      found_command_name = found_command_names.first
      initialize_cmd(all_commands[found_command_name], found_command_name)
    end

    def initialize_cmd(cmd_class, name)
      cmd = cmd_class.new
      if cmd.respond_to?(:shell_command=)
        cmd.shell_command="#{$0} #{name}"
      end
      cmd
    end

    # bin/kaiju command line tool calls this method, which finds the correct class to manage the execution
    def execute(args)
      @use = []
      my_args = opts.parse(args.dup)
      load_scripts
      if my_args.empty?
        KiCommandHelp.new.execute(self, [])
      else
        find_cmd(my_args.delete_at(0)).execute(self, my_args)
      end
    end

    def opts
      o = SimpleOptionParser.new do |opts|
        opts.on("-h", "--home HOME-PATH", "Path to Ki root directory") do |v|
          ki_home(KiHome.new(v))
        end
        opts.on("-u", "--use VER", "Use defined scripts") do |v|
          @use << v
        end
      end
      o
    end
  end

# Displays help for given command
  class KiCommandHelp
    # Summary
    attr_chain :summary, -> { "Displays help for given Ki command" }
    attr_chain :help, -> {""}
    # Finds matching command and displays its help
    def execute(ctx, args)
      if args.size == 1
        puts ctx.find_cmd(args.first).help
        puts "Common ki options:\n#{ctx.opts}"
      else
        finder = ctx.ki_home.finder
        puts <<EOF
ki-repo is a repository for storing packages and metadata.

Usage:
  #{$0} COMMAND parameters

Info:
  Home directory: #{ctx.ki_home.path}
  Repositories:
#{finder.all_repositories.map { |repo| "    - #{repo.path} (components: #{repo.components.size})" }.join("\n")}
  Components in all repositories: #{finder.components.size}

Available commands:
EOF
        KiInfoCommand.new.execute(ctx, ["-c"])

        puts "\nRun '#{$0} help COMMAND' for more information about that command."
      end
    end
  end

# Lists available Ki commands
  class KiInfoCommand
    # Summary
    attr_chain :summary, -> { "Show information about Ki" }
    # Finds all commands under /commands and outputs their id and summary
    def execute(ctx, args)
      opts.parse(args.empty? ? ["-c"] : args)
    end

    def help
      "Test\n#{opts}"
    end

    def opts
      o = SimpleOptionParser.new do |opts|
        opts.on("-c", "--commands", "List commands") do |v|
          commands = KiCommand::CommandRegistry.find(KiCommand::CommandPrefix[0..-2])
          commands.each do |id, service_class|
            puts "  #{id[KiCommand::CommandPrefix.size..-1]}: #{service_class.new.summary}"
          end
        end
        opts.on("-r", "--registered", "List all registered extensions") do |v|
          by_parent = KiCommand::CommandRegistry.by_parent
          by_parent.keys.sort.each do |parent_key|
            puts "#{parent_key}:"
            by_parent[parent_key].each do |url, clazz|
              puts "  - #{url[parent_key.size+1..-1]} (#{clazz.name})"
            end
          end
        end
      end
      o
    end
  end

  KiCommand.register_cmd("help", KiCommandHelp)
  KiCommand.register_cmd("ki-info", KiInfoCommand)

end