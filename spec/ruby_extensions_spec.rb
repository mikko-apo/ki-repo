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

describe Array do
  it "size! should check parameter types" do
    lambda { [].size!(Object) }.should raise_error("'Object' not supported, needs to be either Range or have .to_i method")
    lambda { [].size!(1, 2..3) }.should raise_error("size 0 does not match '1', '2..3'")
  end
  it "wrap should wrap anything other than array to an array" do
    Array(Object).should eq([Object])
    Array([Object]).should eq([Object])
  end
  it "find_first should support block selection" do
    [1, 2].find_first.should eq(1)
    [1, 2].find_first { |i| i==2 }.should eq(2)
    [1, 2].find_first(2).should eq([1, 2])
    [1, 2].find_first(2) { |i| i==2 }.should eq([2])
  end
end

describe Hash do
  it "require should warn if value not defined" do
    {"a" => 1}.require("a").should eq(1)
    lambda { {}.require("a") }.should raise_error("'a' is not defined!")
  end
end

describe File do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "safe_write should write to file" do
    tmp = @tester.tmpdir
    dest = File.join(tmp, "a.t")
    File.safe_write(dest, "1")
    IO.read(dest).should eq("1")
    File.safe_write(dest) do |file|
      file.write("2")
    end
    IO.read(dest).should eq("2")
    lambda do
      File.safe_write(dest) do |file|
        file.write("3")
        raise "foo"
      end
    end.should raise_error("foo")
  end
end

describe Enumerable do
  it "find_first should return first item" do
    class Test
      include Enumerable

      def each(&block)
        (1..10).each do |i|
          block.call(i)
        end
      end
    end
    Test.new.find_first { |c| c==2 }.should eq(2)
  end
  it "to_h should convert list to hash" do
    ["a=1", "b", "c="].separate_to_hash("=").should eq({"a" => "1", "b" => true, "c" => ""})
    ["a=1", "b"].separate_to_hash { |i| i.split("=") }.should eq({"a" => "1", "b" => nil})
  end
end

describe ObjectSpace do
  it "should iterate all classes" do
    ObjectSpace.all_classes
  end
end

describe Object do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should have show_errors" do
    lambda {
    @tester.catch_stdio do
      show_errors do
        raise "foo"
      end
    end
    }.should raise_error("foo")
    @tester.stdout.join.should =~ /Exception 'foo'/
  end

  it "should have try" do
    try(2, 0.0001) {1}.should eq 1
    lambda{try(2, 0.0001) {raise "fails"}}.should raise_error(/fails \(tried 2 times/)
  end
end

describe String do
  it "should split strip" do
    " foo bar ".split_strip.should eq(["foo bar"])
    " foo , bar, baz ,zap ".split_strip.should eq(["foo", "bar", "baz", "zap"])
  end
end