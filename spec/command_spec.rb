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

describe KiCommand do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should display ki help and repository summary if there are no command line parameters" do
    @tester.chdir(@source = @tester.tmpdir)
    @home = KiHome.new(@source)
    Tester.write_files(@source, "readme.txt" => "aa", "test.sh" => "bb")
    KiCommand.new.execute(%W(version-build --version-id my/component/23 -t foo test.sh --source-url http://test.repo/repo@21331 --source-tag-url http://test.repo/tags/23 --source-repotype git --source-author john))
    KiCommand.new.execute(%W(version-import -h #{@home.path}))
    output = @tester.catch_stdio do
      KiCommand.new.execute(%W(-h #{@home.path}))
    end.stdout.join
    output.should =~ /ki-repo/
    output.should =~ /Home directory: #{@source}/
    output.should =~ /- #{@source}\/repositories\/local \(components: 1\)/
    output.should =~ /Components in all repositories: 1/
  end

  it "should have help" do
    KiCommand.new.help.should =~ /the main command line tool/
  end

  it "should warn about unknown command" do
    lambda { KiCommand.new.execute(%W(unknown-command)) }.should raise_error("No commands match: unknown-command")
  end

  it "should have default location for KiHome" do
    @tester.env("KIHOME", nil)
    KiCommand.new.ki_home.path.should eq(File.expand_path(File.join("~","ki")))
  end

  it "should have take KiHome path from ENV[\"KIHOME\"]" do
    tmpdir = @tester.tmpdir
    path = File.join(tmpdir, "foo")
    @tester.env("KIHOME", path)
    KiCommand.new.ki_home.path.should eq(path)
    File.exist?(path).should eq(true)
  end

  it "should support pluggable commands" do
    @tester.restore_extensions
    class TestCommand

    end
    TestCommand.any_instance.expects(:execute).with { |ki_command, params| params.should eq(["123", "456"]) }
    TestCommand.any_instance.expects(:help).returns("Help")
    KiCommand.register_cmd("test-command", TestCommand)
    KiCommand.new.execute(%W(test-command 123 456))
    @tester.catch_stdio do
      KiCommand.new.execute(%W(help test-command))
    end.stdout.join.should =~ /Help/
  end

  it "should list available commands" do
    @tester.restore_extensions
    class TestCommand

    end
    KiCommand.register_cmd("test-command", TestCommand)
    TestCommand.any_instance.expects(:summary).returns("Test command is for testing").twice
    @tester.catch_stdio do
      KiCommand.new.execute(%W(ki-info))
    end.stdout.join.should =~ /Test command is for testing/
    @tester.catch_stdio do
      KiCommand.new.execute(%W(ki-info -c))
    end.stdout.join.should =~ /Test command is for testing/
  end

  it "should list registered things" do
    @tester.catch_stdio do
      KiCommand.new.execute(%W(ki-info -r))
    end.stdout.join.should =~ /sha1 \(Ki::SHA1\)/
  end

  it "should list registered things" do
    @tester.catch_stdio do
      KiCommand.new.execute(%W(help ki-info))
    end.stdout.join.should =~ /shows information about Ki/
  end
end
