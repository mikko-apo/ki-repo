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

require 'tmpdir'

module Ki

  # Automatic resource cleanup that is executed when ruby is closing down
  $testers = []

  at_exit do
    Tester.final_tester_check
  end

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

    # Name of the test round that uses this tester
    attr_reader :test_name

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stdin, -> { DummyIO.new }

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stdout, -> { DummyIO.new }

    # Dummy IO stream
    # @see catch_stdio
    attr_chain :stderr, -> { DummyIO.new }

    def initialize(test_name = nil)
      @test_name = test_name
      @cleaners = []
      $testers << self
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
          Tester.copy_visible_files(src, dest)
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
        if !defined? @original_dir
          @original_dir = Dir.pwd
          @cleaners << -> { Dir.chdir(@original_dir); @original_dir=nil }
        end
        Dir.chdir(dest)
      end
    end

    def env(key, value)
      current = ENV[key]
      @cleaners << -> {ENV[key]=current}
      ENV[key]=value
      self
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

    def clear?
      @cleaners.empty?
    end

    def self.final_tester_check
      catcher = ExceptionCatcher.new
      $testers.each do |tester|
        if !tester.clear?
          puts "Tester#{tester.test_name ? " '#{tester.test_name}'" : ""} has not been cleared! Please add the missing .after() command. Clearing it automatically."
          catcher.catch do
            tester.after
          end
        end
      end
      catcher.check
    end

    # Copies contents of src to dest
    # * excludes files and directories beginning with a '.'
    # @param [String] src source directory path
    # @param [String] dest destination directory path
    # @return [String] dest directory
    def self.copy_visible_files(src, dest)
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
    #   src = Tester.write_files(@tester.tmpdir, "file.txt" => "aa", "dir/my.txt" => "bb")
    def self.write_files(dest_root, files={})
      files.each_pair { |file_path, content|
        dir = File.dirname(file_path)
        if dir != "."
          FileUtils.mkdir_p(File.join(dest_root, dir))
        end
        File.safe_write(File.join(dest_root, file_path), content)
      }
      dest_root
    end

    # Verifies that files exist in target directory.
    # If files or directories are missing, contents are wrong, type is wrong or there are unwanted files raises an exception.
    # @param [String] source_root target directory path
    # @param [List] args containing check_for_extra_files and files map
    #   * check_for_extra_files, by default verify_files does not check if there are other files or directories. If set to true, raises an exception if there are other files
    #   * files, a map of file paths and contents. If file name ends with "/" or file contents are nil, path is a directory
    # @return [Boolean] true if there were no errors
    # @example
    #   @tester.verify_files(tmpdir, "file.txt" => "aa", "dir/my.txt" => "bb", "dir" => nil) # other files are ok
    #   @tester.verify_files(tmpdir, true, "file.txt" => "aa", "dir/my.txt" => "bb", "dir" => nil) # other files will fail
    def self.verify_files(source_root, *args)
      check_for_extra_files, files = args
      if files.nil? && check_for_extra_files.kind_of?(Hash)
        files = check_for_extra_files
        check_for_extra_files = nil
      end
      files.each_pair do |file, contents|
        file_path = File.join(source_root, file)
        is_dir = file.end_with?("/") || contents.nil?
        if !File.exist?(file_path)
          raise "#{ is_dir ? "Directory" : "File"} '#{file_path}' is missing!"
        end
        if is_dir != File.directory?(file_path)
          raise "Existing #{ is_dir ? "file" : "directory"} '#{file_path}' should be a #{ is_dir ? "directory" : "file"}!"
        end
        if !is_dir
          file_contents = IO.read(file_path)
          [contents].flatten.each do |o|
            if o.kind_of?(Regexp)
              if !file_contents.match(o)
                raise "File '#{file_path}' does not match regexp #{o.inspect}, file contents: '#{file_contents}'"
              end
            elsif o.kind_of?(String)
              if file_contents != o
                raise "File '#{file_path}' is broken! Expected '#{o}' but was '#{file_contents}'"
              end
            elsif o.kind_of?(Proc)
              if !o.call(file_contents)
                raise "File '#{file_path}' did not pass test!"
              end
            else
              raise "Unsupported checker! File '#{file_path}' object: #{o.inspect}"
            end
          end
        end
      end
      if check_for_extra_files
        files_and_dirs = {}
        files.each_pair do |k, v|
          file_arr=k.split("/")
          c = file_arr.size
          while c > 0
            c -= 1
            files_and_dirs[File.join(source_root, file_arr)]=true
            file_arr.delete_at(-1)
          end
        end
        Dir.glob(File.join(source_root, "**/*")).each do |file|
          if !files_and_dirs[file]
            raise "#{ File.directory?(file) ? "Directory" : "File"} '#{file}' exists, but it should not exist!"
          end
        end
      end
    end

    # Dummy IO class that implements stream methods
    # @see catch_stdio
    class DummyIO < Array
      def write(s)
        self.<< s
      end

      def puts(s)
        self.<< s + "\n"
      end

      def flush

      end
    end

    def restore_extensions
      original_commands = KiCommand::KiExtensions.dup
      cleaners << lambda do
        KiCommand::KiExtensions.clear
        KiCommand::KiExtensions.register(original_commands)
      end
    end
  end

# Helper class for testing functionality that uses threads
# @example
#    l = ThreadLatch.new
#    thread {l.wait(:b); puts "b";l.tick(:c)}
#    thread {l.wait(:a); puts "a";l.tick(:b);l.tick(:c)}
#    l.tick(:a)
#    l.wait(:c, 2)
#    puts "c"
  class ThreadLatch
    # Turns on debug printing
    attr_accessor :debug

    def initialize
      @lock = Mutex.new
      @cvs = {}
    end

    # Increments counter
    def tick(id=nil)
      @lock.synchronize do
        params = (@cvs[id] ||= [ConditionVariable.new, 0])
        params[1] = params.last + 1

        if @debug
          $stdout.flush
          puts "#{id} tick #{Thread.current.object_id} (count = #{params.last})"
          $stdout.flush
        end

        params.first.broadcast
      end
    end

    # Waits until counter reaches defined value
    # * value can be defined with constructor
    # @param [Object, nil] to To defines target count for wait. If nil and no to values has been given with constructor, to is set to 1
    # @param [Integer, nil] to To defines target count for wait. If nil and no to values has been given with constructor, to is set to 1
    def wait(id=nil, dest=nil)
      @lock.synchronize do
        if dest
          dest = dest.to_i
          raise ArgumentError, "cannot count down from negative integer #{dest}" if dest < 0
        else
          dest=1
        end
        loop = true
        while loop
          cv, count = (@cvs[id] ||= [ConditionVariable.new, 0])
          if count >= dest
            loop = false
            if @debug
              puts "#{id}.released #{Thread.current.object_id} (count = #{count}, dest = #{dest})"
            end
          else
            if @debug
              $stdout.flush
              puts "#{id}.wait #{Thread.current.object_id} (count = #{count}, dest = #{dest})"
              $stdout.flush
            end
            cv.wait(@lock)
          end
        end
      end
    end
  end
end