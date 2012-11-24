require 'spec_helper'

describe DirectoryBase do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "should resolve path with parent" do
    root = DirectoryBase.new("/foo")
    node = DirectoryBase.new("bar").parent(root)
    node.path.should == "/foo/bar"
    node.path("aa").should == "/foo/bar/aa"
    node.path("aa", "bb").should == "/foo/bar/aa/bb"
  end

  it "mkdir should create directories" do
    tmp = @tester.tmpdir
    root = DirectoryBase.new(tmp)
    dest = root.mkdir("foo","bar/zop")
    dest.path.should == "#{tmp}/foo/bar/zop"
    dest.path("a").should == "#{tmp}/foo/bar/zop/a"
  end

  it "exists? should test if file exists" do
    root = DirectoryBase.new(@tester.tmpdir)
    root.exists?.should == true
    root.exists?("a").should == false
    File.safe_write(root.path("a"),"")
    root.exists?("a").should == true
  end
end

describe VersionFileOperations do

  it "edit_file_map mv" do
    files = {
        "foo.txt" => "/tmp/foo.txt",
        "a/b.txt" => "/tmp/a/b.txt",
        "to_dir.txt" => "/tmp/to_dir.txt",
        "a/1.properties" => "/tmp/a/1.properties",
        "2.properties" => "/tmp/a/2.properties",
        "replace.yaml" => "/tmp/replace.yaml",
        "replace_2.yaml" => "/tmp/replace_2.yaml",
        "replace_3.yaml" => "/tmp/replace_3.yaml"
    }
    VersionFileOperations.new.edit_file_map(files, [
        ["mv", "foo.txt", "bar.txt"],
        ["mv", "to_dir.txt", "dir/"],
        ["mv", "*.properties", "properties/"],
        ["mv", "(*_2).yaml", "foo/$1.json"],
        ["mv", "(*_3).yaml", "$1/replace.json"],
        ["mv", "(*).yaml", "$1.json"],
        ["mv", "a/*", "/"]
    ])
    files.should == {
        "bar.txt" => "/tmp/foo.txt",
        "dir/to_dir.txt" => "/tmp/to_dir.txt",
        "properties/1.properties" => "/tmp/a/1.properties",
        "properties/2.properties" => "/tmp/a/2.properties",
        "foo/replace_2.json"=>"/tmp/replace_2.yaml",
        "replace_3/replace.json"=>"/tmp/replace_3.yaml",
        "replace.json"=>"/tmp/replace.yaml",
        "b.txt"=>"/tmp/a/b.txt"
    }
  end

  it "edit_file_map cp" do
    files = {
        "foo.txt" => "/tmp/foo.txt",
        "to_dir.txt" => "/tmp/to_dir.txt",
        "a/1.properties" => "/tmp/a/1.properties",
        "2.properties" => "/tmp/a/2.properties",
        "replace.yaml" => "/tmp/replace.yaml",
        "replace_2.yaml" => "/tmp/replace_2.yaml",
        "replace_3.yaml" => "/tmp/replace_3.yaml"
    }
    VersionFileOperations.new.edit_file_map(files, [
        ["cp", "foo.txt", "bar.txt"],
        ["cp", "to_dir.txt", "dir/"],
        ["cp", "*.properties", "properties/"],
        ["cp", "(*_2).yaml", "foo/$1.json"],
        ["cp", "(*_3).yaml", "$1/replace.json"],
        ["cp", "(*).yaml", "$1.json"]
    ])
    files.should == {
        "foo.txt"=>"/tmp/foo.txt",
        "to_dir.txt"=>"/tmp/to_dir.txt",
        "a/1.properties"=>"/tmp/a/1.properties",
        "2.properties"=>"/tmp/a/2.properties",
        "replace.yaml"=>"/tmp/replace.yaml",
        "replace_2.yaml"=>"/tmp/replace_2.yaml",
        "replace_3.yaml"=>"/tmp/replace_3.yaml",
        "bar.txt"=>"/tmp/foo.txt",
        "dir/to_dir.txt"=>"/tmp/to_dir.txt",
        "properties/1.properties"=>"/tmp/a/1.properties",
        "properties/2.properties"=>"/tmp/a/2.properties",
        "foo/replace_2.json"=>"/tmp/replace_2.yaml",
        "replace_3/replace.json"=>"/tmp/replace_3.yaml",
        "replace.json"=>"/tmp/replace.yaml",
        "replace_2.json"=>"/tmp/replace_2.yaml",
        "replace_3.json"=>"/tmp/replace_3.yaml"
    }
  end

  it "edit_file_map rm" do
    files = {"foo.txt" => "/tmp/foo.txt"}
    VersionFileOperations.new.edit_file_map(files, [["rm", "foo.txt"]])
    files.should == {}
  end
end

describe "Version dependencies" do
  before do
    @tester = Tester.new
  end
  after do
    @tester.after
  end
end