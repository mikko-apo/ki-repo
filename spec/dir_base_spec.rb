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

describe DirectoryBase do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should support find!" do
    root = DirectoryBase.new(@tester.tmpdir)
    test = root.mkdir("test")
    DirectoryBase.find!("test", test, root).ki_path.should eq("/test")
    lambda { DirectoryBase.find!("test/2", test, root) }.should raise_error("Could not find 'test/2' from '#{root.path}/test', '#{root.path}'")
  end

  it "should support root" do
    root = Dir.pwd
    a = DirectoryBase.new(root)
    a.root.should eq a
    b = DirectoryBase.new("b").parent(a)
    b.root.should eq a
  end

  it "should support empty?" do
    root = DirectoryBase.new(@tester.tmpdir)
    root.empty?.should be_true
    FileUtils.touch(root.path("foo.txt"))
    root.empty?.should be_false
  end

  it "should support lock" do
    file_path = File.join(@tester.tmpdir, "foo", "test.json")
    fileA = KiJSONHashFile.new(file_path)
    fileB = KiJSONHashFile.new(file_path)
    latch = ThreadLatch.new
#    latch.debug = true

    Thread.new do
      latch.wait(:a)
      fileB.edit_data do |o|
        o.cached_data["edit"] = "b"
      end
      latch.tick(:b)
    end
    fileA.edit_data do |o|
      o.cached_data["edit"] = "a"
      latch.tick(:a)
      sleep 0.1
    end
    latch.wait(:b)
    fileA.load_data_from_file.should eq("edit" => "b")
  end
end
