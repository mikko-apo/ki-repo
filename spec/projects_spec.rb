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

describe Lab do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @home = KiHome.new(@tester.tmpdir)
    @project = @home.projects.add_item("test/project").mkdir
    @lab = @project.labs.add_item("foo/bar").mkdir
  end

  after do
    @tester.after
  end

  it "properties should load values from parents" do
    hp = @home.my_properties
    hp.cached_data["a"]="1"
    hp.cached_data["b"]="2"
    hp.save
    pp = @project.my_properties
    pp.cached_data["c"]="3"
    pp.save
    lp = @lab.my_properties
    lp.cached_data["d"]=4
    lp.cached_data["a"]=10
    lp.save
    @lab.properties.should == {"a"=>10, "b"=>"2", "c"=>"3", "d"=>4}
  end

  it "access should load permissions from parents" do
    ha = @home.my_permissions
    ha.cached_data << {"path" => "test/project", "permissions"=>["edit permissions"], "users" => ["apo"], "groups" => ["admins"]}
    ha.save
    pa = @project.my_permissions
    pa.cached_data << {"path" => "foo/bar", "permissions"=>["start action", "edit properties"], "groups" => ["project-admins"]}
    pa.save
    @lab.permissions.should == [
        {"path"=>"test/project", "permissions"=>["edit permissions"], "users"=>["apo"], "groups"=>["admins"]},
        {"path"=>"foo/bar", "permissions"=>["start action", "edit properties"], "groups"=>["project-admins"]}
    ]
  end

  it "version() should look up for matching version" do
    @home.repositories.add_item("site").mkdir.components.add_item("test/comp").mkdir.versions.add_version("13")
    @lab.repositories.add_item("project-common").mkdir.components.add_item("ki/core").mkdir
    ki_versions = @project.repositories.add_item("project-common").mkdir.components.add_item("ki/core").mkdir.versions
    ki_versions.add_version("1")
    ki_versions.add_version("2")
    @home.packages.add_item("packages/local").mkdir("ki/core/2")
    @home.packages.add_item("packages/replicated").mkdir("test/comp/13")
    latest = @lab.version("ki/core")
    latest.version_id.should == "ki/core/2"
    latest.name.should == "2"
#    latest.ki_path.should == "/test/project/info/project-common/ki/core/2"
    latest.binaries.ki_path.should == "/packages/local/ki/core/2"
    specific = @lab.version("ki/core/1")
    specific.version_id.should == "ki/core/1"
#    specific.ki_path.should == "/test/project/info/project-common/ki/core/1"
    specific.binaries.should == nil
    replicated = @lab.version("test/comp")
#    replicated.ki_path.should == "/info/site/test/comp/13"
    replicated.binaries.ki_path.should == "/packages/replicated/test/comp/13"
    @lab.version(replicated).should == replicated
  end

  it "version() should look up for matching version based on status" do
    component = @home.repositories.add_item("site").mkdir.components.add_item("test/comp").mkdir
    version_1 = component.versions.add_version("1")
    version_1.mkdir
    version_2 = component.versions.add_version("2")
    @lab.version("test/comp").version_id.should == "test/comp/2"
    @lab.version(@lab.finder.component("test/comp")).version_id.should == "test/comp/2"
    @lab.version("test/comp:Smoke=green").should == nil
    @lab.version("test/comp","Smoke"=>"green").should == nil
    version_1.statuses.add_status("Smoke","green")
    @lab.version("test/comp:Smoke=green").version_id.should == "test/comp/1"
    @lab.version("test/comp","Smoke"=>"green").version_id.should == "test/comp/1"
    c = 0
    @lab.version("test/comp"){|v| c+=1;c==2}.version_id.should == "test/comp/1"
    @lab.version("test/comp"){|v| true}.version_id.should == "test/comp/2"
    @lab.version("test/comp","Smoke"=>"green"){|v| true}.version_id.should == "test/comp/1"
    lambda {@lab.version(1)}.should raise_error("Not supported '1'")
    # status order
    component.status_info.edit_data do |h|
      h["maturity"]=["alpha","beta","gamma"]
    end
    @lab.version("test/comp").version_id.should == "test/comp/2"
    @lab.version("test/comp:maturity>alpha").should == nil
    version_1.statuses.add_status("maturity","alpha")
    @lab.version("test/comp:maturity>=alpha").version_id.should == "test/comp/1"
    version_1.statuses.add_status("maturity","beta")
    @lab.version("test/comp:maturity>alpha").version_id.should == "test/comp/1"
    version_2.mkdir.statuses.add_status("maturity","alpha")
    @lab.version("test/comp:maturity>alpha").version_id.should == "test/comp/1"
    @lab.version("test/comp:maturity>=alpha").version_id.should == "test/comp/2"
    @lab.version("test/comp:maturity>beta").should == nil
    @lab.version("test/comp:maturity>=beta").version_id.should == "test/comp/1"
    @lab.version("test/comp:maturity!=alpha").version_id.should == "test/comp/1"
    @lab.version("test/comp:maturity<beta").version_id.should == "test/comp/2"
    @lab.version("test/comp:maturity<=beta").version_id.should == "test/comp/2"
    lambda {@lab.version("test/comp:maturity<>beta")}.should raise_error("Not supported status operation: 'maturity<>beta'")
  end
end

describe KiHome do
  before do
    @tester = Tester.new(example.metadata[:full_description])
    @home = KiHome.new(@tester.tmpdir)
  end

  after do
    @tester.after
  end

  it "should keep lists of projects, package and package info" do
    @home.packages.add_item("packages/local")
    @home.packages.add_item("packages/replicated")
    @home.projects.add_item("projects/ki")
    @home.projects.add_item("projects/web")
    @home.repositories.add_item("site")
    @home.repositories.add_item("global-ki")
    [@home.projects, @home.packages, @home.repositories].
        map { |list| list.map { |obj| [obj.class, obj.ki_path] } }.should == [
        [
            [Project, "/projects/ki"],
            [Project, "/projects/web"]
        ],
        [
            [Repository::Repository, "/packages/local"],
            [Repository::Repository, "/packages/replicated"]
        ],
        [
            [Repository::Repository, "/info/site"],
            [Repository::Repository, "/info/global-ki"]
        ]
    ]
  end
end
