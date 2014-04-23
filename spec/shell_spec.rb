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
    HashLogShell.new.chdir(Dir.pwd).env({}).root_log(DummyHashLog.new).spawn({}, "true", {})
  end

  it "should notice failed commands" do
    lambda {
      HashLogShell.new.root_log(DummyHashLog.new).spawn("false")
    }.should raise_error("Shell command 'false' failed with exit code 1")
    HashLogShell.new.ignore_error(true).root_log(DummyHashLog.new).spawn("false")
  end

  it "should catch output" do
    HashLogShell.new.root_log(DummyHashLog.new).spawn("echo foo").out.should eq("foo\n")
  end

  it "cleanup should remove dangling processes" do
    log = DummyHashLog.new
    sh = HashLogShell.new.root_log(log)
    Thread.new do
      sh.spawn("echo 1 && sleep 10 && echo 2")
    end
    sleep 0.2
    HashLogShell::RunningPids.list.size.should eq(1)
    HashLogShell.cleanup
    HashLogShell::RunningPids.list.size.should eq(0)
  end

  it "should manage timeout" do
    log = DummyHashLog.new
    sh = HashLogShell.new.root_log(log)
    Thread.new do
      sh.timeout(0.2).spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.list.size.should eq(1)
    sleep 0.2
    HashLogShell::RunningPids.list.size.should eq(0)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds")
  end

  it "should manage timeout function" do
    log = DummyHashLog.new
    a = 0
    sh = HashLogShell.new.root_log(log).timeout(0.2) do |pid|
      a = 1
      Process.kill "KILL", pid
    end
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.list.size.should eq(1)
    a.should eq(0)
    sleep 0.2
    HashLogShell::RunningPids.list.size.should eq(0)
    a.should eq(1)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds")
  end

  it "should manage timeout function and send KILL eventually" do
    log = DummyHashLog.new
    a = 0
    sh = HashLogShell.new.root_log(log).kill_timeout(0.01).timeout(0.2) do |pid|
      a = 1
    end
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.list.size.should eq(1)
    a.should eq(0)
    sleep 0.2
    HashLogShell::RunningPids.list.size.should eq(0)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds and user suplied block did not stop process after 0.01 seconds. Sent TERM.")
    a.should eq(1)
  end

  it "kill_running should kill running process" do
    log = DummyHashLog.new
    sh = HashLogShell.new.root_log(log)
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.list.size.should eq(1)
    sh.kill_running
    sleep 0.1
    HashLogShell::RunningPids.list.size.should eq(0)
  end

  it "should get input from /dev/null" do
    log = DummyHashLog.new
    sh = HashLogShell.new.root_log(log).timeout(1)
    lambda{
      sh.spawn('read -p Do? yn')
    }.should raise_error("Shell command 'read -p Do? yn' failed with exit code 1")

  end
end
