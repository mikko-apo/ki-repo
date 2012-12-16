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

describe ShellCommand do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should collect exitstatus and logs" do
    sh = ShellCommand.new
    sh.run("echo 1;echo 2")
    sh.exitstatus.should eq(0)
    sh.stderr.should eq([])
    sh.stdout.map{|date, str| str}.should eq(["1\n", "2\n"])
  end

  it "should collect exitstatus for failed actions" do
    tmp = @tester.tmpdir
    sh_file = File.join(tmp, "exit_1.sh")
    File.safe_write(sh_file,"#!/usr/bin/env bash\nexit 1")
    ShellCommand.new.system("chmod u+x #{sh_file}")
    sh = ShellCommand.new
    sh.run(sh_file)
    sh.exitstatus.should eq(1)
    sh.stderr.should eq([])
    sh.stdout.should eq([])
  end

end
