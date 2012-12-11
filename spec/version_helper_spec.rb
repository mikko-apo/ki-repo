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

describe VersionTester do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @source = @tester.tmpdir
    Tester.write_files(@source,
                        "same.txt" => "aa",
                        "changed.txt" => "aa",
                        "changed_size.txt" => "aa",
                        "missing.txt" => "aa")
    @metadata_file = File.join(@source, "test.json")
    KiCommand.new.execute(
        ["version-build",
         "--version-id", "my/component/23",
         "-f", @metadata_file,
         "-i", @source,
         "*"
        ])
  end

  after do
    @tester.after
  end

  it "should call supplied block when there are issues" do
    Tester.write_files(@source, "changed.txt" => "bb", "changed_size.txt" => "aaa")
    FileUtils.rm(File.join(@source, "missing.txt"))
    index = 0
    issues = [["wrong hash", "changed.txt"], ["wrong size", "changed_size.txt"], ["missing", "missing.txt"]]
    VersionTester.new.test_version(Version.create_version(@metadata_file, @source)) do |issue, version, file|
      [issue, file].should == issues[index]
       index+=1
    end
  end
end

describe VersionImporter do
  it "should warn about not supported arguments" do
    lambda{VersionImporter.new.import()}.should raise_error("Not supported: '[]'")
  end
end
