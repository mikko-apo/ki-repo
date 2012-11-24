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