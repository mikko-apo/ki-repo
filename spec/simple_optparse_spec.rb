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

describe SimpleOptionParser do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should parse different option types" do
    f = nil
    p = SimpleOptionParser.new do |opt|
      opt.on("-c", "--clear", "clear") do
        f = true
      end
      opt.on("-f", "--file FILE", "read file") do |file|
        f = file
      end
      opt.on("-p", "--parameters P1 P2", "parameters") do |p1, p2|
        f = [p1, p2]
      end
    end
    p.parse(["-c","a"]).should eq(["a"])
    f.should eq(true)
    lambda{p.parse(["-f"])}.should raise_error("requires 1 parameters for '-f', found only 0: ")
    f.should eq(true)
    p.parse(["-f","a"]).should eq([])
    f.should eq("a")
    p.parse(["-f=b"]).should eq([])
    f.should eq("b")
    p.parse(["-p","a","b","c"]).should eq(["c"])
    f.should eq(["a","b"])
  end

  it "should provide to_s" do
    SimpleOptionParser.new do |opt|
      opt.on("-f", "--file FILE", "read file") do |file|
        f = file
      end
    end.to_s.should eq("    -f, --file                       read file")
  end

  it "should warn about errors" do
    lambda {SimpleOptionParser.new { |opt| opt.on("-f")}}.should raise_error("Option without parser block: -f")
    lambda {SimpleOptionParser.new { |opt| opt.on("-f"){}}}.should raise_error("unsupported option configuration size: -f")
  end
end