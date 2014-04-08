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

describe HashLog do
  it "should log hierarchic events" do
    class Foo
      include HashLog
    end
    Time.expects(:now).returns(11, 22, 33, 44).times(4)
    f = Foo.new
    root = nil
    ret = f.log("a") do |l|
      root = l
      f.log("b", "test" => "bar") do
        1
      end
    end
    ret.should == 1
    root.should == {"start" => 11.0, "name" => "a", "logs" => [{"start" => 22.0, "name" => "b", "test" => "bar", "time" => 11.0}], "time" => 33.0}
  end
  it "should log parallel events" do
    Time.expects(:now).returns(11, 22, 33, 44, 55, 66).times(6)
    class Foo
      include HashLog
    end
    f = Foo.new
    latch = ThreadLatch.new
    root_log = nil
    f.log("root") do |l|
      root_log = l
      f.log.should eq(l)
      a = Thread.new do
        latch.wait(:b_ready)
        f.set_hash_log_root_for_thread(l)
        f.log("a") do
        end
        latch.tick(:a_ready)
      end
      b = Thread.new do
        f.set_hash_log_root_for_thread(l)
        f.log("b") do
          latch.tick(:b_ready)
          latch.wait(:a_ready)
        end
      end
      a.join
      b.join
    end
    root_log.should == {"start" => 11.0, "name" => "root", "logs" => [{"start" => 22.0, "name" => "b", "time" => 33.0}, {"start" => 33.0, "name" => "a", "time" => 11.0}], "time" => 55.0}
  end

  it "should log exception" do
    class Foo
      include HashLog
    end
    f = Foo.new
    root_log = nil
    lambda{
      f.log("root") do |l|
        root_log = l
        raise "foo"
      end
    }.should raise_error("foo")
    root_log["exception"].should eq("foo")
  end

  it "should generate a simple log object" do
    class Foo
      include HashLog
    end
    f = Foo.new
    l = f.log("root")
    l["start"].should be_true
  end
end
