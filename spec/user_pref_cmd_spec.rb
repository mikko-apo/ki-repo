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

describe "User prefs" do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @tester.restore_extensions
  end

  after do
    @tester.after
  end

  it "should warn about unknown command" do
    lambda{KiCommand.new.execute(%W(pref foo))}.should raise_error("not supported: foo")
  end

  it "should display help" do
    @tester.catch_stdio do
      KiCommand.new.execute(%W(help pref))
    end.stdout.join.should =~ /Syntax/
  end

  it "prefix" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix -h #{source}))
    end.stdout.join.should eq("Prefixes: \n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix version- -h #{source}))
    end.stdout.join.should eq("Prefixes: version-\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix -h #{source}))
    end.stdout.join.should eq("Prefixes: version-\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix + package- -h #{source}))
    end.stdout.join.should eq("Prefixes: version-, package-\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix - version- -h #{source}))
    end.stdout.join.should eq("Prefixes: package-\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix -c -h #{source}))
    end.stdout.join.should eq("Prefixes: \n")

    # Test that ki command uses prefixes
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix pre -h #{source}))
    end.stdout.join.should eq("Prefixes: pre\n")

    @tester.catch_stdio do
      KiCommand.new.execute(%W(f prefix + version -h #{source}))
    end.stdout.join.should eq("Prefixes: pre, version\n")

    VersionStatus.any_instance.expects(:execute).with { |ctx, args| args.should eq(["test"]) }
    KiCommand.new.execute(%W(status test -h #{source}))
  end

  it "prefix might make multiple commands match" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix version test -h #{source}))
    end.stdout.join.should eq("Prefixes: version, test\n")

    class TestCommand

    end
    KiCommand.register_cmd("test-test", TestCommand)

    lambda { KiCommand.new.execute(%W(test -h #{source})) }.should raise_error("Multiple commands match: version-test, test-test")
  end

  it "prefix shows up in pref list" do
    @tester.chdir(source = @tester.tmpdir)
    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref prefix version test -h #{source}))
    end.stdout.join.should eq("Prefixes: version, test\n")

    @tester.catch_stdio do
      KiCommand.new.execute(%W(pref -h #{source}))
    end.stdout.join.should eq("User preferences:\nprefixes: version, test\n")
  end

  describe "use scripts"do
    before do
      @tester.chdir(@source = @tester.tmpdir)

      # Generate test scripts that are going to be used
      home = KiHome.new(@source)
      [
          ["ki/zip/1", "zip.rb", {}],
          ["ki/bzip2/2", "bzip2.rb", {"Zip" => "Bzip2", "zip" => "bzip2"}]
      ].each do |ver, file, replace|
        @tester.tmpdir do |dir|
          file_source = <<EOF
class ZipTest
  attr_chain :summary, -> { "zipsummary" }
  attr_chain :help, -> { "ziphelp" }
  undef :execute if method_defined? :execute
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
          metadata.add_files(dir, "*", "tags" => "ki-cmd")
          metadata.version_id=ver
          metadata.save
          VersionImporter.new.ki_home(home).import(metadata.path, dir)
        end
      end
    end

    it "preferences" do
      # test that adding use scripts works
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use -h #{@source}))
      end.stdout.join.should eq("Use: \n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use ki/bzip2 -h #{@source}))
      end.stdout.join.should eq("Use: ki/bzip2\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use -h #{@source}))
      end.stdout.join.should eq("Use: ki/bzip2\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use + ki/zip -h #{@source}))
      end.stdout.join.should eq("Use: ki/bzip2, ki/zip\n")

      # test that test scripts are loaded
      @tester.catch_stdio do
        KiCommand.new.execute(%W(bzip2 a b -h #{@source}))
      end.stdout.join.should eq("bzip2:a,b\n")
      command_list_ouput = @tester.catch_stdio do
        KiCommand.new.execute(%W(ki-info -h #{@source}))
      end.stdout.join
      command_list_ouput.should =~ /bzip2summary/
      command_list_ouput.should =~ /zipsummary/

      # test that remove works
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use - ki/zip -h #{@source}))
      end.stdout.join.should eq("Use: ki/bzip2\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use -c -h #{@source}))
      end.stdout.join.should eq("Use: \n")
    end

    it "should support --use scripts from commandline" do
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref use ki/bzip2 -h #{@source}))
      end.stdout.join.should eq("Use: ki/bzip2\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(bzip2 a b -h #{@source}))
      end.stdout.join.should eq("bzip2:a,b\n")
      # when registry cleared, bzip2 is no longer available
      KiCommand::KiExtensions.clear
      lambda {KiCommand.new.execute(%W(-u ki/zip bzip2 a b -h #{@source}))}.should raise_error("No commands match: bzip2")
      # zip is available
      @tester.catch_stdio do
        KiCommand.new.execute(%W(-u ki/zip zip a b -h #{@source}))
      end.stdout.join.should eq("zip:a,b\n")
      # original use restored when -u no defined
      @tester.catch_stdio do
        KiCommand.new.execute(%W(bzip2 a b -h #{@source}))
      end.stdout.join.should eq("bzip2:a,b\n")
    end

    it "should support --require" do
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref require net/http -h #{@source}))
      end.stdout.join.should eq("Require: net/http\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref require --require net/http -h #{@source}))
      end.stdout.join.should eq("Require: net/http\n")
    end

    it "should support --require" do
      test = File.join(@source, "test.rb")
      File.safe_write(test, "")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref load #{test} -h #{@source}))
      end.stdout.join.should eq("Load: #{test}\n")
      @tester.catch_stdio do
        KiCommand.new.execute(%W(pref load --load #{test} -h #{@source}))
      end.stdout.join.should eq("Load: #{test}\n")
    end
  end
end