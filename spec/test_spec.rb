require 'spec_helper'

describe Tester do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "tmpdir should create temp directory and clear it after" do
    tmp = @tester.tmpdir
    tmp_2 = @tester.tmpdir
    File.directory?(tmp).should == true
    File.directory?(tmp_2).should == true
    @tester.after
    File.exists?(tmp).should == false
    File.exists?(tmp_2).should == false
  end

  it "tmpdir should copy visible files" do
    tmp = @tester.tmpdir
    @tester.write_files(tmp, "foo.txt" => "aa", "bar/foo.txt" => "bb", ".config" => "cc", "bar/.config" => "dd")
    FileUtils.mkdir(File.join(tmp, ".test"))
    FileUtils.mkdir(File.join(tmp, "bar/.test"))
    dest = @tester.tmpdir(tmp)
    IO.read(File.join(dest, "foo.txt")).should == "aa"
    IO.read(File.join(dest, "bar/foo.txt")).should == "bb"
    File.exists?(File.join(dest, ".config")).should == false
    File.exists?(File.join(dest, "bar/.config")).should == false
    File.exists?(File.join(dest, ".test")).should == false
    File.exists?(File.join(dest, "bar/.test")).should == false
    block_path = nil
    @tester.tmpdir(tmp) do |path|
       IO.read(File.join(path, "foo.txt")).should == "aa"
       block_path = path
       File.exists?(path).should == true
    end
    File.exists?(block_path).should == false
  end

  it "tmpdir should delete target file if there is exception during setup" do
    @tester.expects(:copy_visible_files).raises("test error")
    FileUtils.expects(:remove_entry_secure)
    lambda {@tester.tmpdir("/non-existing-path-for-testing")}.should raise_error("test error")
  end

  it "catch_stdio should catch output" do
    @tester.catch_stdio do
      puts "foo"
    end
    @tester.stdout.join.should == "foo\n"
    @tester.catch_stdio do
      puts "bar"
    end
    @tester.stdout.join.should == "bar\n"
    @tester.catch_stdio
    puts "zap"
    @tester.stdout.join.should == "zap\n"
  end

  it "chdir should change directory" do
    original = Dir.pwd
    parent = File.dirname(original)
    parent.should_not == original
    @tester.chdir(parent) do
       Dir.pwd.should == parent
    end
    Dir.pwd.should == original
    @tester.chdir(parent)
    Dir.pwd.should == parent
  end
end

