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
    attr_chain :running
    attr_chain :finished
    attr_chain :detached
    attr_chain :chdir

    def finished?
      finished
    end
  end
  class DummyHashLog < Hash
    def log(*arr, &block)
      block.call(self)
    end
  end

  class HashLogShell
    RunningPids = SynchronizedArray.new

    attr_chain :env
    attr_chain :chdir
    attr_chain :ignore_error
    attr_reader :previous
    attr_chain :root_log, :require
    attr_chain :detach
    attr_chain :kill_timeout, -> {5}

    def spawn(*arr)
      @finished = false
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
      if !detach
        if (!run_options[:out])
          rout, wout = IO.pipe
          run_options[:out]=wout
        end
        if (!run_options[:err])
          rerr, werr = IO.pipe
          run_options[:err]=werr
        end
      end
      if (!run_options[:in])
        rd, wr = IO.pipe
        wr.close
        run_options[:in]=rd
      end
      cmd = arr.first
      root_log.log(cmd.split(" ")[0]) do |l|
        l["cmd"]=cmd
        pid = system_spawn(run_env, cmd, run_options)
        HashLogShell::RunningPids << pid
        @previous = ShellCommandExecution.new.
            cmd(cmd).
            pid(pid).
            env(run_env).
            options(run_options).
            running(true).
            finished(false)
        if run_options[:chdir]
          @previous.chdir(run_options[:chdir])
          l["chdir"] = run_options[:chdir]
        end

        # run process and manage detach and timeout
        if detach
          Process.detach(pid)
          exitstatus = 0
          @previous.detached(true)
        else
          pid2 = status = nil
          timeout_exception = nil
          if @timeout
            begin
              Timeout.timeout(@timeout) do
                pid2, status = Process.waitpid2(pid)
              end
            rescue Timeout::Error => e
              timeout_exception = "Timeout after #{@timeout} seconds"

              if @timeout_block
                begin
                  Timeout.timeout(kill_timeout) do
                    begin
                      @timeout_block.call(pid)
                    ensure
                      pid2, status = Process.waitpid2(pid)
                    end
                  end
                rescue Timeout::Error
                  timeout_exception = "Timeout after #{@timeout} seconds and user suplied block did not stop process after #{kill_timeout} seconds. Sent TERM."
                  Process.kill "TERM", pid
                  begin
                    Timeout.timeout(kill_timeout) do
                      pid2, status = Process.waitpid2(pid)
                    end
                  rescue Timeout::Error
                    timeout_exception = "Timeout after #{@timeout} seconds and user suplied block did not stop process after #{kill_timeout} seconds. Sent KILL."
                    Process.kill "KILL", pid
                  end
                end
              else
                Process.kill "TERM", pid
                begin
                  Timeout.timeout(kill_timeout) do
                    pid2, status = Process.waitpid2(pid)
                  end
                rescue Timeout::Error
                  timeout_exception = "Timeout after #{@timeout} seconds and TERM did not stop process after #{kill_timeout} seconds. Sent KILL."
                  Process.kill "KILL", pid
                end
              end
            end
          else
            pid2, status = Process.waitpid2(pid)
          end
          HashLogShell::RunningPids.delete(pid)
          if timeout_exception
            exitstatus = timeout_exception
          else
            exitstatus = status.exitstatus
          end
          @previous.exitstatus(exitstatus)
        end

        @previous.running(false).finished(true)

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
        if exitstatus != 0
          l["exitstatus"] = exitstatus
          if !ignore_error
            raise "Shell command '#{cmd}' failed with exit code #{exitstatus}"
          end
        end
        @previous
      end
    end

    def timeout(time_s, &timeout_block)
      @timeout = time_s
      @timeout_block = timeout_block
      self
    end

    def system_spawn(run_env, cmd, run_options)
      Process.spawn(run_env, cmd, run_options)
    end

    def kill_running(signal="KILL")
      if @previous && @previous.running
        Process.kill(signal, @previous.pid)
      end
    end

    def self.cleanup
      try(10,0.5) do |c|
        HashLogShell::RunningPids.dup.each do |pid|
          Process.kill( c < 5 ? "TERM" : "KILL", pid)
        end
        try(30, 0.1) do
          list = HashLogShell::RunningPids.dup
          if list.size > 0
            raise "Child processes won't die: #{list.join(", ")}"
          end
        end
      end
    end
  end
end