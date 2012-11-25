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

describe ExceptionCatcher do
  it "should return value if no exceptions" do
    catcher = ExceptionCatcher.new
    var = catcher.catch("test") do
      "a"
    end
    var.should == "a"
    catcher.result("test").should == "a"
  end
  it "should return value if no exceptions" do
    catcher = ExceptionCatcher.new
    var = catcher.catch("exp") do
      raise "a"
    end
    var.should == nil
    catcher.result("exp").should == nil
    catcher.exceptions.size.should == 1
    catcher.exception("exp").message.should == "a"
    lambda {catcher.check}.should raise_error(RuntimeError, "a")
  end
  it "should return multiple exceptions" do
    catcher = ExceptionCatcher.new
    catcher.catch("a") do
      raise "a"
    end
    catcher.catch("b") do
      raise "b"
    end
    catcher.exceptions.size.should == 2
    catcher.exception("a").message.should == "a"
    catcher.exception("b").message.should == "b"
    begin
      catcher.check
    rescue => e
      e.message.should == "Caught 2 exceptions!"
      e.class.should == ExceptionCatcher::MultipleExceptions
      e.exceptions.values.map {|exp| exp.message}.should == ["a", "b"]
      e.tasks.should == ["a", "b"]
      e.each {|exp| exp.class.should == RuntimeError}
    end

  end
end

