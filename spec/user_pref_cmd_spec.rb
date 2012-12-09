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
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should warn about unknown command" do
    lambda{KiCommand.new.execute(["pref", "foo"])}.should raise_error("not supported: foo")
  end

  it "should display help" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "pref"])
    end.stdout.join.should =~ /Preferences/
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

    VersionStatus.any_instance.expects(:execute).with { |ctx, args| args.should == ["test"] }
    KiCommand.new.execute(["status", "test"])
  end

  it "prefix might make multiple commands match" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "prefix", "version", "test"])
    end.stdout.join.should == "Prefixes: version, test\n"

    original_commands = KiCommand::CommandRegistry.dup
    @tester.cleaners << lambda do
      KiCommand::CommandRegistry.clear
      KiCommand::CommandRegistry.register(original_commands)
    end
    class TestCommand

    end
    KiCommand.register_cmd("test-test", TestCommand)

    lambda { KiCommand.new.execute(["test"]) }.should raise_error("Multiple commands match: version-test, test-test")
  end

  it "use" do
    @tester.chdir(source = @tester.tmpdir)

    # Generate test scripts that are going to be used
    home = KiHome.new(source)
    [
     ["ki/zip/1", "zip.rb", {}],
     ["ki/bzip2/2", "bzip2.rb", {"Zip" => "Bzip2", "zip" => "bzip2"}]
    ].each do |ver, file, replace|
      @tester.tmpdir do |dir|
        file_source = <<EOF
class ZipTest
  attr_chain :summary, -> { "zipsummary" }
  attr_chain :help, -> { "ziphelp" }
  def execute(a,args)
    puts "zip:\#{args.join(",")}"
  end
end
Ki::KiCommand.register_cmd("zip", ZipTest)
EOF
        replace.each_pair do |from, to|
          file_source.gsub!(from, to)
        end
        Tester.write_files(dir, file => file_source)
        metadata = VersionMetadataFile.new(File.join(dir, "metadata.json"))
        metadata.add_files(dir, "*")
        metadata.version_id=ver
        metadata.save
        VersionImporter.new.ki_home(home).import(metadata.path, dir)
      end
    end

    # test that adding use scripts works
    @tester.catch_stdio do
      KiCommand.new.execute(["pref", "use"])
    end.stdout.join.should == "Use: \n"
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "pref", "use", "ki/bzip2"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "pref", "use"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "pref", "use", "+", "ki/zip"])
    end.stdout.join.should == "Use: ki/bzip2, ki/zip\n"

    # test that test scripts are loaded
    command_list_ouput = @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "commands"])
    end.stdout.join
    command_list_ouput.should =~ /bzip2summary/
    command_list_ouput.should =~ /zipsummary/
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "bzip2", "a", "b"])
    end.stdout.join.should == "bzip2:a,b\n"

    # test that remove works
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "pref", "use", "-", "ki/zip"])
    end.stdout.join.should == "Use: ki/bzip2\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["-h", source, "pref", "use", "-c"])
    end.stdout.join.should == "Use: \n"
  end
end