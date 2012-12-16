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

  # File contains information for user
  class UserPrefFile < KiJSONHashFile
    attr_chain :uses, -> { Array.new }, :accessor => CachedData
    attr_chain :prefixes, -> { Array.new }, :accessor => CachedData

    def initialize
      super("ki-user-pref.json")
    end
  end

  # Sets user specific configurations
  # @see UserPrefFile
  class UserPrefCommand
    attr_chain :shell_command

    def help
<<EOF
#{summary}
Syntax: #{shell_command} prefix|use parameters...

Examples for command prefixes:
  #{shell_command} prefix
  - shows command prefixes, when a "ki command" is executed ki looks for the command with all prefix combinations
  #{shell_command} prefix version package
  - sets two command prefixes, looks for "command", "version-command" and "package-command"
  #{shell_command} prefix + foo
  - adds one command prefix to existing ones, looks for "command", "version-command", "package-command", "foo-command"
  #{shell_command} prefix - package foo
  - removes two command prefixes from list
  #{shell_command} prefix -c
  - clears command prefix list

Examples for automatic script loading:
  #{shell_command} use
  - shows list of automatically loading scripts. when ki starts up, it looks for all defined versions and loads all files tagged with ki-cmd
  #{shell_command} use ki/http ki/ftp/123:ki-extra
  - scripts are loaded from two different version. ki/http uses latest available version and files tagged with "ki-cmd", ki/ftp uses specific version and files tagged with "ki-extra"
  #{shell_command} use + ki/scp
  - adds one more script package version
  #{shell_command} use - ki/scp ki/ftp/123:ki-extra
  - removes two configurations
  #{shell_command} use -c
  - clear use list

EOF
    end

    def summary
      "Sets user preferences"
    end

    def execute(ctx, args)
      user_pref = ctx.user_pref
      pref = args.delete_at(0)
      if pref == "prefix"
        arr = user_pref.prefixes
        str = "Prefixes"
      elsif pref == "use"
        arr = user_pref.uses
        str = "Use"
      elsif pref.nil?
        puts "User preferences:"
        user_pref.cached_data.each_pair do |key, values|
          if values && values.size > 0
            puts "#{key}: " + values.join(", ")
          end
        end
      else
        raise "not supported: " + pref
      end
      if arr && str
        args = opts(arr).parse(args)
        if args.size > 0
          if args[0] == "+"
            args.delete_at(0)
            arr.concat(args)
          elsif args[0] == "-"
            args.delete_at(0)
            args.each do |a|
              arr.delete(a)
            end
          else
            arr.clear
            arr.concat(args)
          end
          arr.uniq!
          user_pref.save
        end
        puts "#{str}: " + arr.join(", ")
      end
    end

    def opts(arr)
      OptionParser.new do |opts|
        opts.banner = ""
        opts.on("-c", "--clear", "Clear existing preferences values for specified value") do |v|
          arr.clear
        end
      end
    end
  end

  KiCommand.register_cmd("pref", UserPrefCommand)
end