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
  class VersionFileOperations
    def resolve_dest_file(file, dest, matching_pattern)
      matcher = matching_pattern.match(file)
      dest = dest.gsub(/\$\d/) do |str|
        matcher[Integer(str[1..-1])]
      end
      if dest.end_with?("/")
        dest = File.join(dest, File.basename(file))
      end
      if dest.start_with?("/")
        dest = dest[1..-1]
      end
      dest
    end

    def copy_or_move(file_map, args, op)
      delete = op == "mv"
      dest = args.delete_at(-1)
      patterns = args.map { |pattern| FileRegexp.matcher(pattern) }
      matching_files = []
      file_map.keys.each do |file|
        matching_pattern = patterns.any_matches?(file)
        if matching_pattern
          matching_files << file
          dest_file = resolve_dest_file(file, dest, matching_pattern)
          file_map[dest_file]=file_map[file]
          if delete
            file_map.delete(file)
          end
        end
      end
    end

    def delete(file_map, args, op)
      patterns = args.map { |pattern| FileRegexp.matcher(pattern) }
      file_map.keys.each do |file|
        if patterns.any_matches?(file)
          file_map.delete(file)
        end
      end
    end

    def edit_file_map(file_map, operations)
      operations.each do |op, *args|
        case op
          when "cp"
            copy_or_move(file_map, args, op)
          when "mv"
            copy_or_move(file_map, args, op)
          when "rm"
            delete(file_map, args, op)
        end
      end
    end

  end

  class FileRegexp
    def FileRegexp.matcher(s)
      /^#{s.gsub(/\./, '\.').gsub('*', ".*")}$/
    end
  end
end