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

  # simplified OptionParser, which supports unknown options by ignoring them
  # * supports options in two formats: "-f file.txt" and "-f=file.txt"
  # * supports short and long form: "--file" and "-f"
  # * supports multiple parameters for options
  # Does not support
  # * parameters with spaces
  # * type conversions
  # * optional parameter values
  class SimpleOptionParser
    attr_chain :options_for_to_s, -> { Array.new }
    attr_chain :options, -> { Array.new }

    def initialize(&block)
      block.call(self)
    end

    def on(*args, &block)
      if block.nil?
        raise "Option without parser block: " + args.join(", ")
      end
      if args.size == 3
        short = args.delete_at(0)
        long, *params = args.delete_at(0).split(" ")
        comment = args.delete_at(0)
        options_for_to_s << {short: short, long: long, comment: comment, params: params, block: block }
        options << {opt: short, comment: comment, params: params, block: block }
        options << {opt: long, comment: comment, params: params, block: block }
      else
        raise "unsupported option configuration size: " + args.join(", ")
      end
    end

    def parse(args)
      ret = []
      open = nil
      collected_params = nil
      collect_count = nil
      args.each do |a|
        if open
          collected_params << a
          if collect_count == collected_params.size
            open[:block].call *collected_params
            open = nil
          end
        else
          found_option, rest_of_a = find_option(a)
          if found_option
            collect_count = found_option[:params].size
            if collect_count == 0
              # no parameters
              found_option[:block].call
            elsif collect_count == 1 && rest_of_a && rest_of_a.size > 0
              # single parameter was defined with opt=value
              found_option[:block].call rest_of_a
            else
              open = found_option
              collected_params = []
            end
          else
            ret << a
          end
        end
      end
      if open
        raise "requires #{collect_count} parameters for '#{open[:opt]}', found only #{collected_params.size}: #{collected_params.join(", ")}"
      end
      ret
    end
    def find_option(a)
      options.each do |o|
        if a.start_with?(o[:opt] + "=")
          return o, a[o[:opt].size+1..-1]
        elsif a.start_with?(o[:opt])
          return o,nil
        end
      end
      nil
    end
    def to_s
      options_for_to_s.map do |o|
      format("    %2s%s %-29s%s",o[:short], o[:short] && o[:long]? ",": " ", o[:long], o[:comment] )
      end.join("\n")
    end
  end
end