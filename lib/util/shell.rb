# encoding: UTF-8

# Copyright 2012-2013 Mikko Apo
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
  # Executes a command and logs using HashLog
  class ShellCommandExecution
    attr_chain :cmd, :require
    attr_chain :exitstatus, :require
    attr_chain :pid, :require
    attr_chain :env, :require
    attr_chain :options, :require
  end
  class DummyHashLog
    def log(*arr, &block)
      block.call
    end
  end
  class HashLogShell
    attr_chain :env
    attr_chain :chdir
    attr_chain :ignore_error
    attr_reader :previous
    attr_chain :root_log, -> {DummyHashLog.new}
    def spawn(*arr)
      run_env = {}
      run_options = {}
      if(env)
        run_env.merge!(env)
      end
      if(arr.first.kind_of?(Hash))
        run_env.merge!(arr.delete_at(0))
      end
      if(arr.last.kind_of?(Hash))
        run_options.merge!(arr.delete_at(-1))
      end
      if(chdir && !run_options[:chdir])
        run_options[:chdir] = chdir
      end
      cmd = arr.first
      root_log.log("Shell command '#{cmd}'") do
        pid = system_spawn(run_env, cmd, run_options)
        pid, status = Process.waitpid2(pid)
        exitstatus = status.exitstatus
        @previous = ShellCommandExecution.new.
            cmd(cmd).
            exitstatus(exitstatus).
            pid(pid).
            env(run_env).
            options(run_options)
        if(exitstatus != 0 && !ignore_error)
          raise "Shell command '#{cmd}' failed with exit code #{exitstatus}"
        end
        @previous
      end
    end

    def system_spawn(run_env, cmd, run_options)
      Process.spawn(run_env, cmd, run_options)
    end
  end
end