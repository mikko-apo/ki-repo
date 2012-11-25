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

describe ServiceRegistry do
  it "should register services" do
    registry = ServiceRegistry.new
    registry.register("/numbers/1" => 1, "/numbers/2" => 2)
    registry.find("/numbers/1").should == 1
    registry.find("/numbers/2").should == 2
    registry.find("/numbers").should == [["/numbers/1", 1], ["/numbers/2", 2]]
    lambda{registry.register(1,2,3)}.should raise_error("Not supported '[1, 2, 3]'")
  end

  it "find_services should find suitable services" do
    registry = ServiceRegistry.new
    registry.register("/numbers/1" => 1, "/numbers/2" => 2)
    registry.find("/numbers").services.should == [1, 2]
  end

  it "find! should warn about bad finds" do
    lambda {ServiceRegistry.new.find!("foo")}.should raise_error("Could not resolve 'foo'")
  end

  it "should identify suitable services based on source material" do
    registry = ServiceRegistry.new
    class TestService
      def supports?(str)
        ["http:","https:"].find_first{|pattern| str.match(pattern)}
      end
    end
    class TestService2
      def supports?(str)
        true
      end
    end
    registry.register("/downloaders/foo", TestService.new).register("/downloaders/bar", TestService2.new)
    registry.find("/downloaders","http://").services.map{|i| i.class}.should == [TestService, TestService2]
    registry.find("/downloaders","ftp://").services.map{|i| i.class}.should == [TestService2]
  end
end