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
    HashLogShell.new.chdir(Dir.pwd).env({}).logger(TestLogger.new).spawn({}, "true", {})
  end

  it "should notice failed commands" do
    lambda {
      HashLogShell.new.logger(TestLogger.new).spawn("false")
    }.should raise_error("Shell command 'false' failed with exit code 1")
    HashLogShell.new.ignore_error(true).logger(TestLogger.new).spawn("false")
  end

  it "should catch output" do
    HashLogShell.new.logger(TestLogger.new).spawn("echo foo").stdout.should eq("foo")
  end

  it "cleanup should remove dangling processes" do
    HashLogShell::RunningPids.dup.size.should eq(0)
    log = TestLogger.new
    sh = HashLogShell.new.logger(log)
    Thread.new do
      sh.spawn("echo 1 && sleep 10 && echo 2")
    end
    sleep 0.2
    HashLogShell::RunningPids.dup.size.should eq(1)
    HashLogShell.cleanup
    HashLogShell::RunningPids.dup.size.should eq(0)
  end

  it "should manage timeout" do
    HashLogShell::RunningPids.dup.size.should eq(0)
    log = TestLogger.new
    sh = HashLogShell.new.logger(log)
    Thread.new do
      sh.timeout(0.2).spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.dup.size.should eq(1)
    sleep 0.2
    HashLogShell::RunningPids.dup.size.should eq(0)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds")
  end

  it "should manage timeout function" do
    HashLogShell::RunningPids.dup.size.should eq(0)
    log = TestLogger.new
    a = 0
    sh = HashLogShell.new.logger(log).timeout(0.2) do |pid|
      a = 1
      Process.kill "KILL", pid
    end
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.dup.size.should eq(1)
    a.should eq(0)
    sleep 0.2
    HashLogShell::RunningPids.dup.size.should eq(0)
    a.should eq(1)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds")
  end

  it "should manage timeout function and send KILL eventually" do
    HashLogShell::RunningPids.dup.size.should eq(0)
    log = TestLogger.new
    a = 0
    sh = HashLogShell.new.logger(log).kill_timeout(0.01).timeout(0.2) do |pid|
      a = 1
    end
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.dup.size.should eq(1)
    a.should eq(0)
    sleep 0.2
    HashLogShell::RunningPids.dup.size.should eq(0)
    sh.previous.exitstatus.should eq("Timeout after 0.2 seconds and user suplied block did not stop process after 0.01 seconds. Sent TERM.")
    a.should eq(1)
  end

  it "kill_running should kill running process" do
    HashLogShell::RunningPids.dup.size.should eq(0)
    log = TestLogger.new
    sh = HashLogShell.new.logger(log)
    Thread.new do
      sh.spawn("sleep 10")
    end
    sleep 0.1
    HashLogShell::RunningPids.dup.size.should eq(1)
    sh.kill_running
    sleep 0.1
    HashLogShell::RunningPids.dup.size.should eq(0)
  end

  it "should get input from /dev/null" do
    log = TestLogger.new
    sh = HashLogShell.new.logger(log).timeout(1)
    lambda{
      sh.spawn('read -p Do? yn')
    }.should raise_error("Shell command 'read -p Do? yn' failed with exit code 1")
  end

  it "should collect output" do
    log = TestLogger.new
    sh = HashLogShell.new.logger(log)
    text1 = "123"
    text2 = "Really long stdout that just goes on and on and on and on and on and on and on and on and on and on and on and on"
    err1 = "This message goes to stderr"
    sh.spawn("echo #{text1}; sleep 1; echo #{err1} >&2; echo #{text2}")
    map_output(sh.previous.output).should eq([["123", nil], ["This message goes to stderr", "e"], ["Really long stdout that just goes on and on and on and on and on and on and on and on and on and on and on and on", nil]])
  end

  it "should collect output with last line" do
    sh = HashLogShell.new.logger(TestLogger.new)
    sh.spawn("echo -n abc")
    sh.previous.stdout.should eq("abc")
  end

  it "should retry" do
    sh = HashLogShell.new.logger(TestLogger.new)
    lambda{sh.retry(5,0.01).spawn("echo abc;exit 1")}.
        should raise_error /Shell command 'echo abc;exit 1' failed with exit code 1 \(tried 5 times, waited .* seconds\)/
  end

  it "should timeout and retry" do
    sh = HashLogShell.new.logger(TestLogger.new)
    lambda{sh.retry(5,0.001).timeout(0.01).spawn("echo 1; sleep 1")}.
        should raise_error /Shell command 'echo 1; sleep 1' failed with exit code Timeout after .* seconds \(tried 5 times, waited .* seconds\)/
  end

  it "should remove extra parameters from log" do
    sh = HashLogShell.new.logger(TestLogger.new)
    previous = sh.extra_parameters(" -foo", " -bar").spawn("echo 123 -foo -bar")
    previous.stdout.should eq("123 -foo -bar")
    previous.log["cmd"].should eq("echo 123")
    previous.log["cmd_original"].should eq("echo 123 -foo -bar")
    previous = sh.extra_parameters(" -foo").spawn("echo 123 -foo -bar")
    previous.stdout.should eq("123 -foo -bar")
    previous.log["cmd"].should eq("echo 123 -bar")
  end

  def map_output(output)
    output.map{|time, type, log| [type, log]}
  end
end
