require 'tmpdir'

module Ki
# Modifies run time environment for tests and automatically restores original state
# * note: cleanup is triggered by calling the {#after} method
#
# @see #cleaners
# @see #tmpdir
# @see #catch_stdio
# @see #chdir
# @see #after
  class Tester
    # List of Procs which should be executed
    # @see after
    attr_reader :cleaners

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stdin, -> { DummyIO.new }

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stdout, -> { DummyIO.new }

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stderr, -> { DummyIO.new }

    def initialize
      @cleaners = []
    end

    # Creates a temporary directory
    # * if called without a block removes directory when after is called
    # @param [String] src tmpdir copies contents of src path if src is defined. note: only visible files are copied. files and directories starting with . are excluded
    # @param [Proc] block if a block is defined, passes the temporary directory path to the block as parameter and removes the directory when the block ends
    # @return [String, Object] If block is not defined, returns the path of the temporary directory. If block is defined, returns the value the block returns.
    # @example
    #   tmp_source = @tester.tmpdir
    #   File.touch(File.join(tmp_source, "file.txt"))
    #   @tester.tmpdir(tmp_source).each do |dest_2|
    #
    #   end
    # @see copy_visible_files
    def tmpdir(src=nil, &block)
      dest = Dir.mktmpdir
      cleanup = -> { FileUtils.remove_entry_secure(dest) }
      if src
        catcher = ExceptionCatcher.new
        catcher.catch do
          copy_visible_files(src, dest)
        end
        # if there is a problem copying files, cleanup and raise original exception
        if catcher.exceptions?
          catcher.catch do
            cleanup.call
          end
          catcher.check
        end
      end
      if block
        begin
          block.call(dest)
        ensure
          cleanup.call
        end
      else
        @cleaners << cleanup
        dest
      end
    end

    # Redirects $stdin, $stdout, $stderr streams to the Tester instance
    # * if called without block, streams are restored when after is called
    # @param [Proc] block if block is defined, restores streams once the block ends
    # @return self which is useful when catch_stdio is called with block because stdin, stdout and stderr are available after the block
    # @example
    #   @tester.catch_stdio do
    #     puts "foo"
    #   end
    #   @tester.stdio.join == "foo\n"
    #
    # @see DummyIO, stdin, stdout, stderr
    def catch_stdio(&block)
      original_streams = [$stdin, $stdout, $stderr]
      cleanup = -> { $stdin, $stdout, $stderr = original_streams }
      stdin.clear
      stdout.clear
      stderr.clear
      $stdin = stdin
      $stdout = stdout
      $stderr = stderr
      if block
        begin
          block.call
        ensure
          cleanup.call
        end
      else
        @cleaners << cleanup
      end
      self
    end

    # Changes working directory to target
    # @param (String) dest target directory
    # @param (Proc) block if block is defined, restores working directory after block ends
    # @return (Object) if block is defined returns block's return value
    # @example
    #   @tester.chdir(dest)
    def chdir(dest, &block)
      if block
        Dir.chdir(dest, &block)
      else
        if @original_dir.nil?
          @original_dir = Dir.pwd
          @cleaners << -> { Dir.chdir(@original_dir); @original_dir=nil }
        end
        Dir.chdir(dest)
      end
    end

    # Executes all pending cleanup operations
    # * cleaners lists all procs that will be executed
    # * all exceptions from procs are caught and raised together
    # * Tester helper methods schedule cleanup operations to cleaners if needed
    # @return [void]
    # @example RSpec test
    #   describe "My tests" do
    #     before do
    #       @tester = Tester.new
    #     end
    #
    #     after do
    #       @tester.after
    #     end
    #
    #     it "should export files" do
    #       dest = @tester.tmpdir
    #     end
    #   end
    #
    # @example Tests can add their own cleanup procs. This reduces the need to write exception management in tests
    #    it "should combine ..." do
    #      dao = DAO.new
    #      @tester.cleaners << -> { dao.rollback }
    #      dao.do_something_that_does_not_cleanup_environment_and_might_raise_exception
    #    end
    #
    # @see ExceptionCatcher, cleaners
    def after
      catcher = ExceptionCatcher.new
      @cleaners.each do |after_block|
        catcher.catch do
          after_block.call
        end
      end
      @cleaners.clear
      catcher.check
    end

    # Copies contents of src to dest
    # * excludes files and directories beginning with a '.'
    # @param [String] src source directory path
    # @param [String] dest destination directory path
    # @return [String] dest directory
    def copy_visible_files(src, dest)
      Dir.glob(File.join(src, "**/*")).each do |file_src|
        file_path = file_src[src.size+1..-1]
        if File.file?(file_src)
          FileUtils.cp(file_src, File.join(dest, file_path))
        elsif File.directory?(file_src)
          FileUtils.mkdir(File.join(dest, file_path))
        end
      end
      dest
    end

    # Writes defined files to target directory
    # * note: dest_root and target directories are automatically created
    # @param [String] dest_root target directory path
    # @param [Hash] files map of files and their contents
    # @return [String] dest_root directory
    # @example
    #   src = @tester.write_files(@tester.tmpdir, "file.txt" => "aa", "dir/my.txt" => "bb")
    def write_files(dest_root, files={})
      files.each_pair { |file_path, content|
        dir = File.dirname(file_path)
        if dir != "."
          FileUtils.mkdir_p(File.join(dest_root, dir))
        end
        File.safe_write(File.join(dest_root, file_path), content)
      }
      dest_root
    end

    # Dummy IO class that implements stream methods
    # @see catch_stdio
    class DummyIO < Array
      def write(s)
        self.<< s
      end
    end
  end
end