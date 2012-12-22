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

class FileGenerator
  attr_chain :root, -> {File.dirname(File.dirname(File.expand_path(__FILE__)))}

  def build_ki_commands_doc
    File.safe_write(File.join(root, "docs", "ki_commands.md")) do |f|
      f.puts "# @title Ki: Command line utilities"
      f.puts "# Command line utilities for Ki Repository v#{KiHome.ki_version}"
      f.puts KiCommand.new.help
      commands = KiCommand::KiExtensions.find(KiCommand::CommandPrefix[0..-2])
      commands.each do |id, clazz|
        f.puts
        cmd = clazz.new
        name = id[KiCommand::CommandPrefix.size..-1]
        if cmd.respond_to?(:shell_command=)
          cmd.shell_command="ki #{name}"
        end
        f.puts "## #{name}: #{cmd.summary}"
        f.puts
        help = cmd.help
        f.write help
        if !help.end_with?("\n")
          f.puts
        end
      end
    end
  end
end