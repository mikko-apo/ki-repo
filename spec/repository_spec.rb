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

describe Repository do
  before do
    @tester = Tester.new(example.metadata[:full_description])
  end

  after do
    @tester.after
  end

  it "should support json loading" do
    package_info = Repository::Repository.new(@tester.tmpdir)
    File.safe_write(package_info.components.path, JSON.pretty_generate(["my/component/in/sub/directory"]))
    component = package_info.components.size!(1).first
    component.component_id.should == "my/component/in/sub/directory"
    component.path.should == package_info.path("my/component/in/sub/directory")
    File.safe_write(component.mkdir.versions.path, JSON.pretty_generate([{"id" => "124", "date" => Time.now},
                                                                         {"id" => "123", "date" => Time.now - 2}
                                                                        ]))
    version = component.versions.size!(2).first
    version.path.should == package_info.path("my/component/in/sub/directory/124")
    version.version_id.should == "my/component/in/sub/directory/124"
  end

  it "should support helper methods to add components and versions" do
    package_info = Repository::Repository.new(@tester.tmpdir)
    package_info.components.add_item("my/component/in/sub/directory")
    component = package_info.component("my/component/in/sub/directory")
    component.component_id.should == "my/component/in/sub/directory"
    component.path.should == package_info.path("my/component/in/sub/directory")
    component.mkdir
    versions = component.versions
    versions.add_version("123", Time.now - 2)
    versions.add_version("124")
    version = component.versions.size!(2).first
    version.path.should == package_info.path("my/component/in/sub/directory/124")
    version.version_id.should == "my/component/in/sub/directory/124"
    version.mkdir.reverse_dependencies.add_item("my/component/in/sub/directory/123")
    version.reverse_dependencies.size!(1).first.should == "my/component/in/sub/directory/123"
  end
end

describe Repository::Version do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @package_info = Repository::Repository.new(@tester.tmpdir)
    @component = @package_info.components.add_item("my/component/in/sub/directory").mkdir
    @version = @component.versions.add_version("124").mkdir
  end

  after do
    @tester.after
  end

  it "should status helper methods" do
    statuses = @version.statuses
    statuses.add_status("Smoke", "green", "action"=>"/projects/hours/lab-1")
    statuses.add_status("Regression", "Red")
    statuses.matching_statuses("Smoke").should == [{"key"=>"Smoke", "value"=>"green", "action"=>"/projects/hours/lab-1"}]
  end

  it "metadata should have helper methods" do
    metadata = @version.metadata
    metadata.version_id.should == "my/component/in/sub/directory/124"
    metadata.version_id = "my/component/1"
    metadata.add_file_info("bar.txt", 123, :executable => true, "sha-1" => "11aa33")
    metadata.add_file_info("foo.txt", 124, ["doc", "bar"], :executable => true, "sha-1" => "11aa33")
    dep = metadata.add_dependency("tests/runner/123", "name" => "test", "path" => "tests", "internal" => true)
    dep.add_operation(["rm", "*.txt"])
    dep.add_operation(["cp", "*.txt", "foo"])
    metadata.add_dependency("my/doc/223,name=doc,path=docs,internal")
    metadata.source(
        "repotype" => "git",
        "url" => "https://git.foo.fi/repo:016d28b8c4959a3d28d2fbfb4b86c0361aad74ef",
        "tag" => "https://git.foo.fi/repo:my-component-1",
        "author" => "apo"
    )
    metadata.add_operation(["rm", "*.info"])
    metadata.save
    @version.metadata.cached_data.should == {
        "version_id"=>"my/component/1",
        "source"=>{
            "repotype"=>"git",
            "url"=>"https://git.foo.fi/repo:016d28b8c4959a3d28d2fbfb4b86c0361aad74ef",
            "tag"=>"https://git.foo.fi/repo:my-component-1",
            "author"=>"apo"
        },
        "files"=>[
            {"path"=>"bar.txt", "size"=>123, "executable"=>true, "sha-1"=>"11aa33"},
            {"path"=>"foo.txt", "size"=>124, "executable"=>true, "sha-1"=>"11aa33", "tags"=>["doc", "bar"]}
        ],
        "dependencies"=>[
            {"version_id"=>"tests/runner/123",
             "name" => "test",
             "path"=>"tests",
             "internal"=>true,
             "operations"=>[
                 ["rm", "*.txt"],
                 ["cp", "*.txt", "foo"]
             ]
            },
            {"version_id"=>"my/doc/223",
             "name"=>"doc",
             "path"=>"docs",
             "internal"=>true}
        ],
        "operations"=>[["rm", "*.info"]]
    }
  end
end
