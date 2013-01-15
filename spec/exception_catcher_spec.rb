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

describe ExceptionCatcher do
  it "should return value if no exceptions" do
    catcher = ExceptionCatcher.new
    var = catcher.catch("test") do
      "a"
    end
    var.should eq("a")
    catcher.result("test").should eq("a")
  end
  it "should return value if no exceptions" do
    catcher = ExceptionCatcher.new
    var = catcher.catch("exp") do
      raise "a"
    end
    var.should eq(nil)
    catcher.result("exp").should eq(nil)
    catcher.exceptions.size.should eq(1)
    catcher.exception("exp").message.should eq("a")
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
    catcher.exceptions.size.should eq(2)
    catcher.exception("a").message.should eq("a")
    catcher.exception("b").message.should eq("b")
    begin
      catcher.check
    rescue => e
      e.message.should eq("Caught 2 exceptions!")
      e.class.should eq(ExceptionCatcher::MultipleExceptions)
      e.exceptions.values.map {|exp| exp.message}.should eq(["a", "b"])
      e.tasks.should eq(["a", "b"])
      e.each {|exp| exp.class.should eq(RuntimeError)}
    end

  end
end

