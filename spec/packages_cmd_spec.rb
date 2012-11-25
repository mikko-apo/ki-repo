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

describe KiCommand do
  before do
    @tester = Tester.new
  end
  after do
    @tester.after
  end

  it "version-build" do
    @tester.chdir(source = @tester.tmpdir) do
      Tester.write_files(source,
                          "dir/test.txt" => "aa",
                          "foo.txt" => "f",
                          "zap.zip" => "ff",
                          "script.sh" => "shell script",
                          "not-included/bar.zip" => "f")
      system("chmod u+x script.sh")
      KiCommand.new.execute(
          ["version-build",
           "--version-id", "my/component/23",
           "--file-hashes", "sha1,md5,sha2",
           "*.sh",
           "--file-tags", "tests,bar",
           "*.zip", "dir",
           "-d", "my/tests/a/123,path=test,name=tests,internal",
           "-o", "rm *.info",
           "-d", "my/docs/4411",
           "-O", "cp foo.txt foo2.txt"
          ]
      )
      KiCommand.new.execute(
          ["version-build",
           "--source-url", "https://foo.fi/repo1",
           "--source-tag-url", "https://foo.fi/repo1",
           "--source-repotype", "git",
           "--source-author", "apo",
          ]
      )
      file = VersionMetadataFile.new("ki-metadata.json")
      file.load_latest_data.should == {
          "version_id"=>"my/component/23",
          "source"=>{
              "url"=>"https://foo.fi/repo1",
              "tag-url"=>"https://foo.fi/repo1",
              "repotype"=>"git", "author"=>"apo"
          },
          "files"=>[
              {"path"=>"dir/test.txt", "size"=>2, "tags"=>["bar", "tests"],
               "md5"=>"4124bc0a9335c27f086f24ba207a4912", "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37",
               "sha2"=>"961b6dd3ede3cb8ecbaacbd68de040cd78eb2ed5889130cceb4c49268ea4d506"},
              {"path"=>"script.sh", "size"=>12, "executable"=>true, "tags"=>["bar", "tests"],
               "md5"=>"257c560384c287268c6d5096f827b9ba", "sha1"=>"6347583f73bdb545b8dad745124cf62421d7aa3c",
               "sha2"=>"3d71079cbf751bb3e1b725aac4db9cbd73352f8773d5f66ddd5bd0bac8cba77c"},
              {"path"=>"zap.zip", "size"=>2, "tags"=>["bar", "tests"],
               "md5"=>"633de4b0c14ca52ea2432a3c8a5c4c31", "sha1"=>"ed70c57d7564e994e7d5f6fd6967cea8b347efbc",
               "sha2"=>"05a9bf223fedf80a9d0da5f73f5c191a665bf4a0a4a3e608f2f9e7d5ff23959c"}
          ],
          "operations"=>[
              ["cp", "foo.txt", "foo2.txt"]
          ],
          "dependencies"=>[
              {"version_id"=>"my/tests/a/123",
               "path"=>"test", "name"=>"tests",
               "internal"=>true,
               "operations"=>[["rm", "*.info"]]},
              {"version_id"=>"my/docs/4411"}
          ]
      }
    end
  end

  it "version-build should support destination file and separate output dir" do
    source = @tester.tmpdir
    Tester.write_files(source, "a/test.txt" => "aa")
    @tester.chdir(@tester.tmpdir) do
      KiCommand.new.execute(
          ["version-build",
           "--version-id", "my/component/23",
           "-f", "test.json",
           "-i", source,
           "*"
          ])
      file = VersionMetadataFile.new("test.json")
      file.load_latest_data.should == {
          "version_id"=>"my/component/23",
          "files"=>[
              {"path"=>"a/test.txt",
               "size"=>2,
               "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37"}
          ]
      }
    end
  end

  it "version-build should warn about config problems" do
    lambda { KiCommand.new.execute(["version-build", "-o", "werwre"]) }.should raise_error("'previous_dep' has not been set: Define a dependency before -o or --operation")
  end

  it "version-build help should output text" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-build"])
    end.stdout.join.should =~ /FILE/
  end

end

describe "version-test" do
  before do
    @tester = Tester.new
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

  it "should test files" do
    file = VersionMetadataFile.new(@metadata_file)
    file.load_latest_data.should == {
        "version_id"=>"my/component/23",
        "files"=>[
            {"path"=>"changed.txt", "size"=>2, "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
            {"path"=>"changed_size.txt", "size"=>2, "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
            {"path"=>"missing.txt", "size"=>2, "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
            {"path"=>"same.txt", "size"=>2, "sha1"=>"e0c9035898dd52fc65c41454cec9c4d2611bfb37"}]
    }
    @tester.catch_stdio do
      KiCommand.new.execute(
          ["version-test",
           "-f", @metadata_file,
           "-i", @source,
           "*"
          ])
    end.stdout.join.should == "All files ok.\n"
  end

  it "should warn about missing and changed files" do
    Tester.write_files(@source, "changed.txt" => "bb", "changed_size.txt" => "aaa")
    FileUtils.rm(File.join(@source, "missing.txt"))
    @tester.catch_stdio do
      KiCommand.new.execute(
          ["version-test",
           "-f", @metadata_file,
           "-i", @source,
           "*"
          ])
    end.stdout.join.should == "#{@source}/test.json: 'changed.txt' wrong hash '#{@source}/changed.txt'
#{@source}/test.json: 'changed_size.txt' wrong size '#{@source}/changed_size.txt'
#{@source}/test.json: 'missing.txt' missing '#{@source}/missing.txt'\n"
  end

  it "help should output text" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-test"])
    end.stdout.join.should =~ /Test/
  end

  it "should load file from current directory" do
    @tester.catch_stdio do
      @tester.chdir(@source) do
        KiCommand.new.execute(["version-test", "-f", "test.json"])
      end
    end.stdout.join.should == "All files ok.\n"
  end

  it "should test versions recursively and by version id" do
    home = KiHome.new(@source)
    test_comp_13_metadata_dir = home.package_infos.add_item("site").mkdir.components.add_item("test/comp").mkdir.versions.add_version("13").mkdir
    test_product_1_metadata = home.package_infos.add_item("site").mkdir.components.add_item("test/product").mkdir.versions.add_version("1").mkdir
    test_comp_13_binary = home.packages.add_item("packages/local").mkdir.components.add_item("test/comp").mkdir.versions.add_version("13").mkdir
    Tester.write_files(test_comp_13_binary.path, "aa.txt" => "aa")
    test_comp_13_metadata_dir.metadata.add_files(test_comp_13_binary.path, "*").save
    product_metadata = test_product_1_metadata.metadata
    product_metadata.add_dependency("test/comp/13,name=comp,path=comp")
    product_metadata.save
#    @tester.catch_stdio do
#      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "test/product/1", "-r"])
#    end.stdout.join.should == "All files ok.\n"
    Tester.write_files(test_comp_13_binary.path, "aa.txt" => "bb")
#    @tester.catch_stdio do
#      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "test/product/1"])
#    end.stdout.join.should == "All files ok.\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "test/product/1", "-r"])
    end.stdout.join.should == "#{home.path}/info/site/test/comp/13/ki-metadata.json: 'aa.txt' wrong hash '#{home.path}/packages/local/test/comp/13/aa.txt'\n"
  end
end

describe "version-import" do
  before do
    @tester = Tester.new
    @source = @tester.tmpdir
    Tester.write_files(@source, "same.txt" => "aa", "foo/changed.txt" => "aa")
    @metadata_file = File.join(@source, "test.json")
    KiCommand.new.execute(
        ["version-build",
         "--version-id", "my/component/23",
         "-f", @metadata_file,
         "*"
        ])
  end

  after do
    @tester.after
  end

  it "should import version" do
    home = KiHome.new(@source)
    KiCommand.new.execute(
        ["version-import",
         "-f", @metadata_file,
         "-i", @source,
         "-t",
         "-h", home.path
        ])
    ver = home.version("my/component")
    ver.version_id.should == "my/component/23"
    @tester.catch_stdio do
      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "my/component/23"])
    end.stdout.join.should == "All files ok.\n"
  end

  it "should test version" do
    Tester.write_files(@source, "foo/changed.txt" => "bb")
    @tester.catch_stdio do
      lambda {
        KiCommand.new.execute(
            ["version-import",
             "-f", @metadata_file,
             "-i", @source,
             "-h", @source
            ])
      }.should raise_error("Files are not ok!")
    end.stdout.join.should == "#{@source}/test.json: 'foo/changed.txt' wrong hash '#{@source}/foo/changed.txt'\n"
  end

  it "help should output text" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-import"])
    end.stdout.join.should =~ /Test/
  end

  it "version-export should export files as links" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-export"])
    end.stdout.join.should =~ /Test/

    home = KiHome.new(@source)
    KiCommand.new.execute(
        ["version-import",
         "-f", @metadata_file,
         "-i", @source,
         "-h", home.path
        ])
    out = @tester.tmpdir
    KiCommand.new.execute(
        ["version-export",
         "my/component",
         "-o", out,
         "-h", home.path
        ])
    File.readlink(File.join(out, "same.txt")).should == "#{@source}/packages/local/my/component/23/same.txt"
    IO.read(File.join(out, "same.txt")).should == "aa"
    File.readlink(File.join(out, "foo/changed.txt")).should == "#{@source}/packages/local/my/component/23/foo/changed.txt"
    IO.read(File.join(out, "foo/changed.txt")).should == "aa"
    # test before export should warn about broken files
    Tester.write_files(@source, "packages/local/my/component/23/same.txt" => "bb")
    @tester.catch_stdio do
      lambda do
      KiCommand.new.execute(
          ["version-export",
           "my/component",
           "-o", out,
           "-h", home.path,
           "-t"
          ])
      end.should raise_error("Files are not ok!")
    end.stdout.join.should == "#{@source}/info/site/my/component/23/ki-metadata.json: 'same.txt' wrong hash '#{@source}/packages/local/my/component/23/same.txt'\n"
  end
  it "version-status add status to my/component" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help","version-status"])
    end.stdout.join.should =~ /Test/
    home = KiHome.new(@source)
    home.package_infos.add_item("site").mkdir.components.add_item("my/component").mkdir.versions.add_version("1.2.3").mkdir
    KiCommand.new.execute(["version-status","add","my/component/1.2.3","Smoke","Green","action=path/123", "-h", @source])
    KiJSON.load_json(home.path("info/site/my/component/1.2.3/ki-statuses.json")).should == [{"key"=>"Smoke", "value"=>"Green", "action"=>"path/123"}]
  end
  it "version-status handles unknown" do
    lambda{ KiCommand.new.execute(["version-status","del"]) }.should raise_error("Not supported 'del'")
  end
end
