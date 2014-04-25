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
    attr_chain :output, :require
    attr_chain :running
    attr_chain :finished
    attr_chain :detached
    attr_chain :chdir

    def finished?
      finished
    end

    def stdout
      output.select {|time, type, log| type == "o"}.map{|time, type, log| log}.join("\n")
    end
  end

  class IOStore
    attr_reader :reader, :writer, :buf

    def initialize(reader, writer)
      @reader = reader
      @writer = writer
      @buf = ''
      @open = true
    end

    def readlines
      if !@open
        return []
      end
      ret = []
      r = nil

      begin
        while true
          @buf += reader.read_nonblock(80)
        end
      rescue
      end

      arr = @buf.split("\n")
      if arr.length == 1 && @buf.end_with?("\n")
        ret << arr.delete_at(0)
        @buf = ""
      else
        while arr.size > 1
          ret << arr.delete_at(0)
        end
        @buf = arr[0]
      end
      ret
    end

    def close
      @open = false
      @reader.close
      @writer.close
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
    attr_chain :kill_timeout, -> { 5 }

    def spawn(*arr)
      @finished = false
      run_env = {}
      run_options = {}
      parse_options_env(arr, run_options, run_env)
      output = out_store = err_store = nil
      if !detach
        if (!run_options[:out])
          rout, wout = IO.pipe
          run_options[:out]=wout
          out_store = IOStore.new(rout, wout)
        end
        if (!run_options[:err])
          rerr, werr = IO.pipe
          run_options[:err]=werr
          err_store = IOStore.new(rerr, werr)
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
        @previous = setup_previous(cmd, pid, l, run_env, run_options)

        # run process and manage detach and timeout
        if detach
          Process.detach(pid)
          exitstatus = 0
          @previous.detached(true)
        else
          timeout_exception = status = logger = nil
          mutex = Mutex.new
          start = l.fetch("start")

          # logger reads output from spawned process
          if out_store || err_store
            l["output"] = output = []
            previous.output(output)
            logger = Thread.new do
              while true
                io_objects = IO.select([rout, rerr].compact)
                mutex.synchronize do
                  io_objects[0].each do |io_object|
                    if io_object == rout
                      handle_input(output, start, "o", out_store)
                    end
                    if io_object == rerr
                      handle_input(output, start, "e", err_store)
                    end
                  end
                end
              end
            end
          end

          # decide if we should manage timeouts or just wait for the process to finish
          if @timeout && @timeout > 0 && ( (remaining = start + @timeout - Time.now.to_f) > 0)
            begin
              Timeout.timeout(remaining) do
                pid2, status = Process.waitpid2(pid)
              end
            rescue Timeout::Error => e
              status, timeout_exception = handle_timeout(pid, status)
            end
          else
            pid2, status = Process.waitpid2(pid)
          end

          # close logger and drain outputs
          if logger
            mutex.synchronize do
              logger.exit
            end
            logger.join
            if out_store
              handle_input(output, @start, "o", out_store)
              out_store.close
            end

            if err_store
              handle_input(output, @start, "e", err_store)
              err_store.close
            end
          end

          if timeout_exception
            exitstatus = timeout_exception
          else
            exitstatus = status.exitstatus
          end
          @previous.exitstatus(exitstatus)
        end

        if rd
          rd.close
        end

        HashLogShell::RunningPids.delete(pid)

        @previous.running(false).finished(true)

        if exitstatus != 0
          l["exitstatus"] = exitstatus
          if !ignore_error
            raise "Shell command '#{cmd}' failed with exit code #{exitstatus}"
          end
        end
        @previous
      end
    end

    def handle_input(output, start, type, store)
      store.readlines.each do |line|
        output << [HashLog.round_to_ms(Time.now.to_f - start), type, line]
      end
    end

    def handle_timeout(pid, status)
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
      return status, timeout_exception
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

    private

    def setup_previous(cmd, pid, log, run_env, run_options)
      previous = ShellCommandExecution.new.
          cmd(cmd).
          pid(pid).
          env(run_env).
          options(run_options).
          running(true).
          finished(false)

      if run_options[:chdir]
        previous.chdir(run_options[:chdir])
        log["chdir"] = run_options[:chdir]
      end

      previous
    end

    def parse_options_env(arr, run_options, run_env)
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
    end

    public

    def self.cleanup
      try(10, 0.5) do |c|
        HashLogShell::RunningPids.dup.each do |pid|
          Process.kill(c < 5 ? "TERM" : "KILL", pid)
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