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

    # Command classes are registered using this method
    def self.register_cmd(name, clazz)
      register(CommandPrefix + name, clazz)
    end

    def self.register(name, clazz)
      CommandRegistry.register(name, clazz)
    end

    def self.new_cmd(name)
      initialize_cmd(CommandRegistry.find!(CommandPrefix + "#{name}"), name)
    end

    def self.initialize_cmd(cmd_class, name)
      cmd = cmd_class.new
      if cmd.respond_to?(:shell_command=)
        cmd.shell_command="#{$0} #{name}"
      end
      cmd
    end

    # bin/kaiju command line tool calls this method, which finds the correct class to manage the execution
    def execute(args)
      if args.empty?
        KiCommandHelp.new.execute([])
      else
        my_args = args.dup
        KiCommand.new_cmd(my_args.delete_at(0)).execute(my_args)
      end
    end
  end

# Displays help for given command
  class KiCommandHelp
    # Summary
    attr_chain :summary, -> { "Displays help for given Ki command" }
    # Finds matching command and displays its help
    def execute(args)
      if args.size == 1
        puts KiCommand.new_cmd(args.first).help
      else
        puts <<EOF
ki-repo is a repository for storing packages and metadata.

Usage:
  #{$0} COMMAND parameters

Available commands:
EOF
        KiCommandList.new.execute(nil)

        puts "\nRun '#{$0} help COMMAND' for more information about that command."
      end
    end
  end

# Lists available Ki commands
  class KiCommandList
    # Summary
    attr_chain :summary, -> { "Lists available Ki commands" }
    # Finds all commands under /commands and outputs their id and summary
    def execute(args)
      commands = KiCommand::CommandRegistry.find(KiCommand::CommandPrefix[0..-2])
      commands.each do |id, service_class|
        puts "  #{id[KiCommand::CommandPrefix.size..-1]}: #{service_class.new.summary}"
      end
    end
  end

  KiCommand.register_cmd("help", KiCommandHelp)
  KiCommand.register_cmd("commands", KiCommandList)

end