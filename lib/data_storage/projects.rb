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

module Ki
  module ProjectMethods
    # merged with parents
    def properties
      parent_properties = {}
      if @parent
        parent_properties = @parent.properties
      end
      parent_properties.merge(my_properties.cached_data)
    end

    def my_properties
      KiJSONHashFile.new("ki-properties.json").parent(self)
    end

    # lookup breath first, then depth
    def resources

    end

    # build, collector build, check_phase, launch
    #  def scheduled_actions
    #    ScheduledActions.new("ki-schedule.json").parent(self)
    #  end

    # List of path, user/group, access rights
    def permissions
      parent_permissions = []
      if @parent
        parent_permissions = @parent.permissions
      end
      parent_permissions + my_permissions.cached_data
    end

    def my_permissions
      KiJSONListFile.new("ki-permissions.json").parent(self)
    end

    DirectoryWithChildrenInListFile.add_list_file(self, PackageInfo::PackageInfo)

    class PackageInfoListFile
      def create_list_item(item)
        PackageInfo::PackageInfo.new("info/" + item).parent(parent).package_info_id(item)
      end
    end

    def package_collector
      PackageFinder.new(self)
    end

    def version(*args, &block)
      # find component definitions which define versions
      package_collector.version(*args, &block)
    end
  end

  class Lab < DirectoryBase
    include ProjectMethods
    attr_chain :lab_id, :require
  end

  class Project < DirectoryBase
    include ProjectMethods
    attr_chain :project_id, :require
    DirectoryWithChildrenInListFile.add_list_file(self, Lab)
  end

  class KiHome < DirectoryBase
    include ProjectMethods
    DirectoryWithChildrenInListFile.add_list_file(self, Project)
    DirectoryWithChildrenInListFile.add_list_file(self, PackageInfo::PackageInfo, "package")
  end

  class ScheduledActions < KiJSONHashFile
    attr_chain :builds, -> { Array.new }, :accessor => CachedDataAccessor.new
  end
end