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
    @tester = Tester.new(example.metadata[:full_description])
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
           "--hashes", "sha1,md5,sha2",
           "*.sh",
           "-t", "tests,bar",
           "-d", "my/tests/a/123,path=test,name=tests,internal",
           "-o", "rm *.info",
           "-d", "my/docs/4411",
           "-O", "cp foo.txt foo2.txt"
          ]
      )
      KiCommand.new.execute(%W(version-build *.zip dir -t tests,bar --hashes sha1,md5,sha2))
      KiCommand.new.execute(
          ["version-build",
           "--source-url", "https://foo.fi/repo1",
           "--source-tag-url", "https://foo.fi/repo1",
           "--source-repotype", "git",
           "--source-author", "apo",
          ]
      )
      file = VersionMetadataFile.new("ki-version.json")
      file.load_data_from_file.should eq({
                                             "version_id" => "my/component/23",
                                             "source" => {
                                                 "url" => "https://foo.fi/repo1",
                                                 "tag-url" => "https://foo.fi/repo1",
                                                 "repotype" => "git", "author" => "apo"
                                             },
                                             "files" => [
                                                 {"path" => "script.sh", "size" => 12, "executable" => true, "tags" => ["bar", "tests"],
                                                  "md5" => "257c560384c287268c6d5096f827b9ba", "sha1" => "6347583f73bdb545b8dad745124cf62421d7aa3c",
                                                  "sha2" => "3d71079cbf751bb3e1b725aac4db9cbd73352f8773d5f66ddd5bd0bac8cba77c"},
                                                 {"path" => "dir/test.txt", "size" => 2, "tags" => ["bar", "tests"],
                                                  "md5" => "4124bc0a9335c27f086f24ba207a4912", "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37",
                                                  "sha2" => "961b6dd3ede3cb8ecbaacbd68de040cd78eb2ed5889130cceb4c49268ea4d506"},
                                                 {"path" => "zap.zip", "size" => 2, "tags" => ["bar", "tests"],
                                                  "md5" => "633de4b0c14ca52ea2432a3c8a5c4c31", "sha1" => "ed70c57d7564e994e7d5f6fd6967cea8b347efbc",
                                                  "sha2" => "05a9bf223fedf80a9d0da5f73f5c191a665bf4a0a4a3e608f2f9e7d5ff23959c"}
                                             ],
                                             "operations" => [
                                                 ["cp", "foo.txt", "foo2.txt"]
                                             ],
                                             "dependencies" => [
                                                 {"version_id" => "my/tests/a/123",
                                                  "path" => "test", "name" => "tests",
                                                  "internal" => true,
                                                  "operations" => [["rm", "*.info"]]},
                                                 {"version_id" => "my/docs/4411"}
                                             ]
                                         })
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
      file.load_data_from_file.should eq({
                                             "version_id" => "my/component/23",
                                             "files" => [
                                                 {"path" => "a/test.txt",
                                                  "size" => 2,
                                                  "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}
                                             ]
                                         })
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

  it "should test files" do
    file = VersionMetadataFile.new(@metadata_file)
    file.load_data_from_file.should eq({
                                           "version_id" => "my/component/23",
                                           "files" => [
                                               {"path" => "changed.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
                                               {"path" => "changed_size.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
                                               {"path" => "missing.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"},
                                               {"path" => "same.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}]
                                       })
    @tester.catch_stdio do
      KiCommand.new.execute(
          ["version-test",
           "-f", @metadata_file,
           "-i", @source
          ])
    end.stdout.join.should eq("All files ok.\n")
  end

  it "should warn about missing and changed files" do
    Tester.write_files(@source, "changed.txt" => "bb", "changed_size.txt" => "aaa")
    FileUtils.rm(File.join(@source, "missing.txt"))
    @tester.catch_stdio do
      KiCommand.new.execute(
          ["version-test",
           "-f", @metadata_file,
           "-i", @source
          ])
    end.stdout.join.should eq("#{@source}/test.json: 'changed.txt' wrong hash '#{@source}/changed.txt'
#{@source}/test.json: 'changed_size.txt' wrong size '#{@source}/changed_size.txt'
#{@source}/test.json: 'missing.txt' missing '#{@source}/missing.txt'\n")
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
    end.stdout.join.should eq("All files ok.\n")
  end

  it "should test versions recursively and by version id" do
    home = KiHome.new(@source)
    test_comp_13_metadata_dir = home.repositories.add_item("site").mkdir.components.add_item("test/comp").mkdir.versions.add_version("13").mkdir
    test_product_1_metadata = home.repositories.add_item("site").mkdir.components.add_item("test/product").mkdir.versions.add_version("1").mkdir
    Tester.write_files(test_comp_13_metadata_dir.path, "aa.txt" => "aa")
    test_comp_13_metadata_dir.metadata.add_files(test_comp_13_metadata_dir.path, "*").save
    product_metadata = test_product_1_metadata.metadata
    product_metadata.add_dependency("test/comp/13,name=comp,path=comp")
    product_metadata.save
#    @tester.catch_stdio do
#      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "test/product/1", "-r"])
#    end.stdout.join.should eq("All files ok.\n"
    Tester.write_files(test_comp_13_metadata_dir.path, "aa.txt" => "bb")
#    @tester.catch_stdio do
#      KiCommand.new.execute(["version-test", "-h", home.path, "-v", "test/product/1"])
#    end.stdout.join.should eq("All files ok.\n"
    @tester.catch_stdio do
      KiCommand.new.execute(["version-test", "-h", home.path, "test/product/1", "-r"])
    end.stdout.join.should eq("#{home.path}/repositories/site/test/comp/13/ki-version.json: 'aa.txt' wrong hash '#{home.path}/repositories/site/test/comp/13/aa.txt'\n")
  end
end

describe "version-import" do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @source = @tester.tmpdir
    @original_files = {"same.txt" => "aa", "foo/changed.txt" => "aa"}
    Tester.write_files(@source, @original_files)
    @metadata_file = File.join(@source, "test.json")
    KiCommand.new.execute(%W(version-build --version-id my/component/23 -f #{@metadata_file} *))
  end

  after do
    @tester.after
  end

  it "should import version" do
    KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source} -t))
    home = KiHome.new(@source)
    ver = home.version("my/component")
    ver.version_id.should eq("my/component/23")
    @tester.catch_stdio do
      KiCommand.new.execute(["version-test", "-h", home.path, "my/component/23"])
    end.stdout.join.should eq("All files ok.\n")
  end

  it "should import version, move files and define product id" do
    repo = @tester.tmpdir
    FileUtils.rm(@metadata_file)
    KiCommand.new.execute(%W(version-build -f #{@metadata_file} *))

    # import first version
    KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{repo} -t -c test/component))
    home = KiHome.new(repo)
    v1 = home.version("test/component")
    v1.version_id.should eq "test/component/1"
    v1.metadata.cached_data.should eq({"files" => [{"path" => "foo/changed.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}, {"path" => "same.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}], "version_id" => "test/component/1"})
    Tester.verify_files(@source, @original_files)

    # import second version
    KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{repo} -t -c test/component -m))
    Dir.glob(File.join(@source, "**/*")).should eq []
    v2 = home.version("test/component")
    v2.version_id.should eq "test/component/2"
    v2.metadata.cached_data.should eq({"files" => [{"path" => "foo/changed.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}, {"path" => "same.txt", "size" => 2, "sha1" => "e0c9035898dd52fc65c41454cec9c4d2611bfb37"}], "version_id" => "test/component/2"})
  end

  it "should import version with specific id" do
    KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source} -v test/component/2 -t))
    home = KiHome.new(@source)
    ver = home.version("test/component")
    ver.version_id.should eq("test/component/2")
    @tester.catch_stdio do
      KiCommand.new.execute(["version-test", "-h", home.path, "test/component"])
    end.stdout.join.should eq("All files ok.\n")
  end

  it "should test version" do
    Tester.write_files(@source, "foo/changed.txt" => "bb")
    @tester.catch_stdio do
      lambda {
        KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source}))
      }.should raise_error("Files are not ok!")
    end.stdout.join.should eq("#{@source}/test.json: 'foo/changed.txt' wrong hash '#{@source}/foo/changed.txt'\n")
  end

  it "should warn about existing version" do
    KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source} -t))
    lambda {
      KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source} -t))
    }.should raise_error("'my/component/23' exists in repository already!")
  end

  it "should warn about bad parameters" do
    FileUtils.rm_rf(@metadata_file)
    KiCommand.new.execute(%W(version-build -f #{@metadata_file} *))
    lambda {
      KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source}))
    }.should raise_error("'version_id' has not been set")
    lambda {
      KiCommand.new.execute(%W(version-import -f #{@metadata_file} -i #{@source} -h #{@source} -c foo -v foo/1))
    }.should raise_error("Can't define both specific_version_id 'foo/1' and create_new_version 'foo'!")
  end

  it "help should output text" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-import"])
    end.stdout.join.should =~ /Test/
  end
end

describe "version-status" do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @tester.chdir(@source = @tester.tmpdir)
    @home = KiHome.new(@source)
    @home.repositories.add_item("local").mkdir.components.add_item("my/component").mkdir.versions.add_version("1.2.3").mkdir
  end

  after do
    @tester.after
  end

  it "should display help" do
    @tester.catch_stdio do
      KiCommand.new.execute(%W(help version-status))
    end.stdout.join.should =~ /Test/
  end

  it "add status to my/component" do
    KiCommand.new.execute(%W(version-status add my/component/1.2.3 Smoke=Green action=path/123 -h #{@source}))
    KiJSONFile.load_json(@home.path("repositories/local/my/component/1.2.3/ki-statuses.json")).should eq([{"key" => "Smoke", "value" => "Green", "action" => "path/123"}])
    @home.version("my/component").statuses.should eq([["Smoke", "Green"]])
  end

  it "set status order to my/component" do
    KiCommand.new.execute(%W(version-status order my/component maturity alpha,beta,gamma -h #{@source}))
    @home.finder.component("my/component").status_info.should eq({"maturity" => ["alpha", "beta", "gamma"]})
  end

  it "handles unknown" do
    lambda { KiCommand.new.execute(["version-status", "del"]) }.should raise_error("Not supported 'del'")
  end
end

describe "version-export" do
  before do
    create_product_component
  end

  after do
    @tester.after
  end

  it "should print help" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-export"])
    end.stdout.join.should =~ /Test/
  end

  it "should export files as links" do
    out = @tester.tmpdir
    KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path}))

    Tester.verify_files(out, true, {"README" => "aa", "readme.txt" => "aa", "test.bat" => "bb", "comp/test.sh" => "bb"})
    File.readlink(File.join(out, "README")).should eq("#{@source}/repositories/local/my/product/2/readme.txt")
    File.readlink(File.join(out, "readme.txt")).should eq("#{@source}/repositories/local/my/product/2/readme.txt")
    File.readlink(File.join(out, "test.bat")).should eq("#{@source}/repositories/local/my/component/23/test.sh")
    File.readlink(File.join(out, "comp/test.sh")).should eq("#{@source}/repositories/local/my/component/23/test.sh")
    # test before export should warn about broken files
    Tester.write_files(@source, "repositories/local/my/component/23/test.sh" => "cc")
    @tester.catch_stdio do
      lambda do
        KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path} -t))
      end.should raise_error("Files are not ok!")
    end.stdout.join.should eq("#{@source}/repositories/local/my/component/23/ki-version.json: 'test.sh' wrong hash '#{@source}/repositories/local/my/component/23/test.sh'\n")
  end

  it "should export selected files" do
    out = @tester.tmpdir
    KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path} readme*))
    Tester.verify_files(out, true, {"README" => "aa", "readme.txt" => "aa"})
  end

  it "should export selected files as copies" do
    out = @tester.tmpdir
    KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path} readme* -c))
    Tester.verify_files(out, true, {"README" => "aa", "readme.txt" => "aa"})
    File.symlink?(File.join(out, "README")).should eq(false)
  end

  it "should export selected files by tag" do
    out = @tester.tmpdir
    KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path} --tags no-match))
    Tester.verify_files(out, true, {})
    KiCommand.new.execute(%W(version-export my/product -o #{out} -h #{@home.path} --tags bar,bop))
    Tester.verify_files(out, true, {"README" => "aa", "readme.txt" => "aa"})
  end
end

describe "version-show" do
  before do
    create_product_component
  end

  after do
    @tester.after
  end

  it "should show imported version" do
    @tester.catch_stdio do
      KiCommand.new.execute(["help", "version-show"])
    end.stdout.join.should =~ /Test/

    product_txt = "Version: my/product/2
Dependencies(1):
my/component/23: internal=true, name=comp, path=comp
Depedency operations:
cp comp/test.sh test.bat
Files(1):
readme.txt - size: 2, sha1=e0c9035898dd52fc65c41454cec9c4d2611bfb37, tags=bar
Version operations(1):
cp readme.txt README
"
    product_dirs = "Version directories: #{@source}/repositories/local/my/product/2, #{@source}/repositories/local/my/product/2\n"
    product_local_dir = "Version directories: #{Dir.pwd}\n"
    component_str = "Version: my/component/23
Source: author=john, repotype=git, tag-url=http://test.repo/tags/23, url=http://test.repo/repo@21331
Files(1):
test.sh - size: 2, sha1=9a900f538965a426994e1e90600920aff0b4e8d2, tags=foo
"
    component_dirs = "Version directories: #{@source}/repositories/local/my/component/23, #{@source}/repositories/local/my/component/23\n"
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-show -h #{@home.path} my/product))
    end.stdout.join.should eq(product_txt)
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-show -h #{@home.path} my/product -r -d))
    end.stdout.join.should eq(product_txt + product_dirs + component_str + component_dirs)
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-show -h #{@home.path} -f ki-version.json -i #{@source} -d))
    end.stdout.join.should eq(product_txt + product_local_dir)
  end
end

def create_product_component
  @tester = Tester.new(example.metadata[:full_description])
  @tester.chdir(@source = @tester.tmpdir)
  @home = KiHome.new(@source)
  Tester.write_files(@source, "readme.txt" => "aa", "test.sh" => "bb")
  KiCommand.new.execute(%W(version-build --version-id my/component/23 -t foo test.sh --source-url http://test.repo/repo@21331 --source-tag-url http://test.repo/tags/23 --source-repotype git --source-author john))
  KiCommand.new.execute(%W(version-import -h #{@home.path}))
  FileUtils.rm("ki-version.json")
  KiCommand.new.execute(%W(version-build --version-id my/product/2 -t bar readme.txt -d my/component/23,name=comp,path=comp,internal) <<
                            "-o" << "cp comp/test.sh test.bat" << "-O" << "cp readme.txt README")
  KiCommand.new.execute(%W(version-import -h #{@home.path}))
end

describe "version-search" do
  before do
    create_product_component
  end

  after do
    @tester.after
  end

  it "should search" do
    @tester.catch_stdio do
      KiCommand.new.execute(%W(help version-search))
    end.stdout.join.should =~ /Test/
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-search my/component -h #{@source}))
    end.stdout.join.should eq("my/component/23\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-search my/* -h #{@source}))
    end.stdout.join.should eq("Found components(2):\nmy/component\nmy/product\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-search *pro* -h #{@source}))
    end.stdout.join.should eq("Found components(1):\nmy/product\n")
    @tester.catch_stdio do
      KiCommand.new.execute(%W(version-search pro -h #{@source}))
    end.stdout.join.should eq("'pro' does not match versions or components\n")
  end
end
