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
  module PackageInfo
    class Version < DirectoryBase
      attr_chain :version_id, :require

      # see VersionMetadataFile
      def metadata
        VersionMetadataFile.new("ki-metadata.json").json_default("version_id" => version_id).parent(self)
      end

      def statuses
        VersionStatusFile.new("ki-statuses.json").parent(self)
      end

      def reverse_dependencies
        KiJSONListFile.new("ki-reverse-dependencies.json").parent(self)
      end

      def action_usage

      end
    end

    class Component < DirectoryBase
      attr_chain :component_id, :require
      DirectoryWithChildrenInListFile.add_list_file(self, Version)

      # Chronological list of versions in this component
      class VersionListFile
        def create_list_item(item)
          id = item["id"]
          Version.new(id).version_id(File.join(parent.component_id, id)).parent(parent)
        end

        def add_version(id, time=Time.now)
          obj = {"id" => id, "time" => time}
          edit_data do |list|
            list.unshift obj
          end
          create_list_item(obj)
        end
      end

      def status_info
        KiJSONHashFile.new("status_info.json").parent(self)
      end
    end

    class PackageInfo < DirectoryBase
      attr_chain :package_info_id, :require
      DirectoryWithChildrenInListFile.add_list_file(self, Component)

      def version(str)
        args = str.split("/")
        args.delete_at(-1)
        component(args.join("/")).version(str)
      end
    end
  end
end

