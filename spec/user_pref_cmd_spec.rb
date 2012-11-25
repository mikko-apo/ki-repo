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

describe "User prefs" do
  before do
    @tester = Tester.new
  end

  after do
    @tester.after
  end

  it "prefix" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix"])
    end.stdout.join.should == "Prefixes: \n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "version-"])
    end.stdout.join.should == "Prefixes: version-\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix"])
    end.stdout.join.should == "Prefixes: version-\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "+", "package-"])
    end.stdout.join.should == "Prefixes: version-, package-\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "-", "version-"])
    end.stdout.join.should == "Prefixes: package-\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "-c"])
    end.stdout.join.should == "Prefixes: \n"

    # Test that ki command uses prefixes
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "pre"])
    end.stdout.join.should == "Prefixes: pre\n"

    @tester.catch_stdio do
      KiCommand.new.execute(["f", "prefix", "+", "version"])
    end.stdout.join.should == "Prefixes: pre, version\n"

    VersionStatus.any_instance.expects(:execute).with{|ctx, args| args.should == ["test"]}
    KiCommand.new.execute(["status", "test"])
  end

  it "use" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use"])
    end.stdout.join.should == "Use: \n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use", "ki/bzip2"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use", "+", "ki/zip"])
    end.stdout.join.should == "Use: ki/bzip2, ki/zip\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use", "-", "ki/zip"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use", "-c"])
    end.stdout.join.should == "Use: \n"
  end
end