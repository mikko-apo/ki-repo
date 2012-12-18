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
end