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

require 'spec_helper'

describe Tester do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "tmpdir should create temp directory and clear it after" do
    tmp = @tester.tmpdir
    tmp_2 = @tester.tmpdir
    File.directory?(tmp).should eq(true)
    File.directory?(tmp_2).should eq(true)
    @tester.after
    File.exists?(tmp).should eq(false)
    File.exists?(tmp_2).should eq(false)
  end

  it "tmpdir should copy visible files" do
    tmp = @tester.tmpdir
    Tester.write_files(tmp, "foo.txt" => "aa", "bar/foo.txt" => "bb", ".config" => "cc", "bar/.config" => "dd")
    FileUtils.mkdir(File.join(tmp, ".test"))
    FileUtils.mkdir(File.join(tmp, "bar/.test"))
    dest = @tester.tmpdir(tmp)
    IO.read(File.join(dest, "foo.txt")).should eq("aa")
    IO.read(File.join(dest, "bar/foo.txt")).should eq("bb")
    File.exists?(File.join(dest, ".config")).should eq(false)
    File.exists?(File.join(dest, "bar/.config")).should eq(false)
    File.exists?(File.join(dest, ".test")).should eq(false)
    File.exists?(File.join(dest, "bar/.test")).should eq(false)
    block_path = nil
    @tester.tmpdir(tmp) do |path|
       IO.read(File.join(path, "foo.txt")).should eq("aa")
       block_path = path
       File.exists?(path).should eq(true)
    end
    File.exists?(block_path).should eq(false)
  end

  it "tmpdir should delete target file if there is exception during setup" do
    Tester.expects(:copy_visible_files).raises("test error")
    FileUtils.expects(:remove_entry_secure)
    lambda {@tester.tmpdir("/non-existing-path-for-testing")}.should raise_error("test error")
  end

  it "catch_stdio should catch output" do
    @tester.catch_stdio do
      puts "foo"
    end
    @tester.stdout.join.should eq("foo\n")
    @tester.catch_stdio do
      puts "bar"
    end
    @tester.stdout.join.should eq("bar\n")
    @tester.catch_stdio
    puts "zap"
    @tester.stdout.join.should eq("zap\n")
  end

  it "chdir should change directory" do
    original = Dir.pwd
    parent = File.dirname(original)
    parent.should_not eq(original)
    @tester.chdir(parent) do
       Dir.pwd.should eq(parent)
    end
    Dir.pwd.should eq(original)
    @tester.chdir(parent)
    Dir.pwd.should eq(parent)
  end

  it "should write files and check that files are correct" do
    tmp = @tester.tmpdir
    files = {"a" => "1", "b/c.txt" => "2"}
    Tester.write_files(tmp, files)
    IO.read(File.join(tmp, "a")).should eq("1")
    IO.read(File.join(tmp, "b/c.txt")).should eq("2")
    Tester.verify_files(tmp, files)
    Tester.verify_files(tmp, "b/" => nil)
    Tester.verify_files(tmp, "b" => nil)
    Tester.verify_files(tmp, "a" => /1/)
    Tester.verify_files(tmp, "a" => lambda { |s| s == "1"} )
    lambda {Tester.verify_files(tmp, files.merge("a" => "bar"))}.should raise_error "File '#{tmp}/a' is broken! Expected 'bar' but was '1'"
    lambda {Tester.verify_files(tmp, "a" => /2/)}.should raise_error "File '#{tmp}/a' does not match regexp /2/, file contents: '1'"
    lambda {Tester.verify_files(tmp, "a" => lambda { |s| s == "2"} )}.should raise_error "File '#{tmp}/a' did not pass test!"
    lambda {Tester.verify_files(tmp, files.merge("foo" => "bar"))}.should raise_error "File '#{tmp}/foo' is missing!"
    lambda {Tester.verify_files(tmp, "c/" => nil)}.should raise_error "Directory '#{tmp}/c/' is missing!"
    lambda {Tester.verify_files(tmp, "b" => "foo")}.should raise_error "Existing directory '#{tmp}/b' should be a file!"
    lambda {Tester.verify_files(tmp, true, "b/c.txt" => "2")}.should raise_error "File '#{tmp}/a' exists, but it should not exist!"
    lambda {Tester.verify_files(tmp, true, "a" => "1")}.should raise_error "Directory '#{tmp}/b' exists, but it should not exist!"
    lambda {Tester.verify_files(tmp, true, "a" => 1)}.should raise_error "Unsupported checker! File '#{tmp}/a' object: 1"
  end

  it "final_tester_check should check for dirty testers" do
    @tester.catch_stdio do
      @tester.cleaners << -> { puts "foo"}
      Tester.final_tester_check
    end.stdout.join.should eq("Tester 'Ki::Tester final_tester_check should check for dirty testers' has not been cleared! Please add the missing .after() command. Clearing it automatically.\nfoo\n")
  end
end

