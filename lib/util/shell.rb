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
    attr_chain :out, :require
    attr_chain :err, :require
  end
  class DummyHashLog < Hash
    def log(*arr, &block)
      block.call(self)
    end
  end
  class HashLogShell
    attr_chain :env
    attr_chain :chdir
    attr_chain :ignore_error
    attr_reader :previous
    attr_chain :root_log, :require

    def spawn(*arr)
      run_env = {}
      run_options = {}
      if (env)
        run_env.merge!(env)
      end
      if (arr.first.kind_of?(Hash))
        run_env.merge!(arr.delete_at(0))
      end
      if (arr.last.kind_of?(Hash))
        run_options.merge!(arr.delete_at(-1))
      end
      if (chdir && !run_options[:chdir])
        run_options[:chdir] = chdir
      end
      rout = wout = rerr = werr = nil
      if (!run_options[:out])
        rout, wout = IO.pipe
        run_options[:out]=wout
      end
      if (!run_options[:err])
        rerr, werr = IO.pipe
        run_options[:err]=werr
      end
      cmd = arr.first
      root_log.log(cmd.split(" ")[0]) do |l|
        l["cmd"]=cmd
        pid = system_spawn(run_env, cmd, run_options)
        pid, status = Process.waitpid2(pid)
        exitstatus = status.exitstatus
        @previous = ShellCommandExecution.new.
            cmd(cmd).
            exitstatus(exitstatus).
            pid(pid).
            env(run_env).
            options(run_options)
        if rout
          wout.close
          out = rout.readlines.join("\n")
          if out.strip.size == 0
            @previous.out(nil)
          else
            @previous.out(out)
            l["stdout"]=@previous.out
          end
          rout.close
        end
        if rerr
          werr.close
          err = rerr.readlines.join("\n")
          if err.strip.size == 0
            @previous.err(nil)
          else
            @previous.err(err)
            l["stderr"]=@previous.err
          end
          rerr.close
        end
        if (exitstatus != 0 && !ignore_error)
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