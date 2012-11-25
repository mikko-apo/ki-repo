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
    attr_chain :uses, -> { Array.new }, :accessor => CachedDataAccessor.new
    attr_chain :prefixes, -> { Array.new }, :accessor => CachedDataAccessor.new

    def initialize
      super("ki-user-pref.json")
    end
  end

  class UserPrefCommand
    attr_chain :user_pref, -> { UserPrefFile.new }

    def help
      "Preferences #{opts(nil)}"
    end

    def summary
      "Sets user preferences"
    end

    def execute(ctx, args)
      pref = args.delete_at(0)
      if pref == "prefix"
        arr = user_pref.prefixes
        str = "Prefixes"
      elsif pref == "use"
        arr = user_pref.uses
        str = "Use"
      else
        raise "not supported: " + pref
      end
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

    def opts(arr)
      OptionParser.new do |opts|
        opts.on("-c", "--clear", "Clear existing preferences values for specified value") do |v|
          arr.clear
        end
      end
    end
  end

  KiCommand.register_cmd("pref", UserPrefCommand)
end