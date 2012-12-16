# encoding: UTF-8

# Copyright 2012 Mikko Apo
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

describe DirectoryBase do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should resolve path with parent" do
    root = DirectoryBase.new("/foo")
    node = DirectoryBase.new("bar").parent(root)
    node.path.should eq("/foo/bar")
    node.path("aa").should eq("/foo/bar/aa")
    node.path("aa", "bb").should eq("/foo/bar/aa/bb")
  end

  it "mkdir should create directories" do
    tmp = @tester.tmpdir
    root = DirectoryBase.new(tmp)
    dest = root.mkdir("foo","bar/zop")
    dest.path.should eq("#{tmp}/foo/bar/zop")
    dest.path("a").should eq("#{tmp}/foo/bar/zop/a")
  end

  it "exists? should test if file exists" do
    root = DirectoryBase.new(@tester.tmpdir)
    root.exists?.should eq(true)
    root.exists?("a").should eq(false)
    File.safe_write(root.path("a"),"")
    root.exists?("a").should eq(true)
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
    files.should eq({
        "bar.txt" => "/tmp/foo.txt",
        "dir/to_dir.txt" => "/tmp/to_dir.txt",
        "properties/1.properties" => "/tmp/a/1.properties",
        "properties/2.properties" => "/tmp/a/2.properties",
        "foo/replace_2.json"=>"/tmp/replace_2.yaml",
        "replace_3/replace.json"=>"/tmp/replace_3.yaml",
        "replace.json"=>"/tmp/replace.yaml",
        "b.txt"=>"/tmp/a/b.txt"
    })
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
    files.should eq({
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
    })
  end

  it "edit_file_map rm" do
    files = {"foo.txt" => "/tmp/foo.txt"}
    VersionFileOperations.new.edit_file_map(files, [["rm", "foo.txt"]])
    files.should eq({})
  end
end

describe "Version dependencies" do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end
  after do
    @tester.after
  end
end