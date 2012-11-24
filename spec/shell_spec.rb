require 'spec_helper'

describe ShellCommand do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "should collect exitstatus and logs" do
    sh = ShellCommand.new
    sh.run("echo 1;echo 2")
    sh.exitstatus.should == 0
    sh.stderr.should == []
    sh.stdout.map{|date, str| str}.should == ["1\n", "2\n"]
  end

  it "should collect exitstatus for failed actions" do
    tmp = @tester.tmpdir
    sh_file = File.join(tmp, "exit_1.sh")
    File.safe_write(sh_file,"#!/usr/bin/env bash\nexit 1")
    ShellCommand.new.system("chmod u+x #{sh_file}")
    sh = ShellCommand.new
    sh.run(sh_file)
    sh.exitstatus.should == 1
    sh.stderr.should == []
    sh.stdout.should == []
  end

end
