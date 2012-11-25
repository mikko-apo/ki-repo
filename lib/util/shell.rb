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

require 'open4'

module Ki
# Fake logger, can be used to log stderr & stdout
# * logged rows are available as items containing Time,String
  class ShellLogger < Array
    # Stores Time.now,str pairs
    def <<(str)
      super([Time.now, str])
    end
  end

# Open4 based shell command launcher, blocks until command has finished
# * possible to read stdout, stderr and exitstats
# * stdin is given as input for the process
# * for testing, override system
  class ShellCommand
    # Exit status of the previous command
    attr_chain :exitstatus, :require
    # Stdin for the previous process
    attr_chain :stdin, -> { "" }
    # Stdout of the previous process
    attr_chain :stdout, -> { ShellLogger.new }
    # Stderr of the previous process
    attr_chain :stderr, -> { ShellLogger.new }

    # Executes the given command
    # @param [String] cmd Cmd is the shell command which is started. Uses current process' ENV
    def run(cmd)
      system(cmd)
    end

    # Use run instead. Extracted from run for easier testing
    def system(cmd)
      stdout.clear
      stderr.clear
      status = Open4::spawn(cmd, 'stdout' => stdout, 'stderr' => stderr, 'stdin' => stdin, 'ignore_exit_failure' => true)
      @exitstatus = status.exitstatus
    end
  end
end