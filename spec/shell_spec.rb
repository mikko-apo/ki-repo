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

describe HashLogShell do
  it "should execute simple command succesfully" do
    HashLogShell.new.chdir(Dir.pwd).env({}).spawn({}, "true", {})
  end
  it "should notice failed commands" do
    lambda {
      HashLogShell.new.spawn("false")
    }.should raise_error("Shell command 'false' failed with exit code 1")
    HashLogShell.new.ignore_error(true).spawn("false")
  end
  it "should catch output" do
    HashLogShell.new.spawn("echo foo").out.should eq("foo\n")
  end
end
