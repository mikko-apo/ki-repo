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

module Ki
  module Repository
    # Contains information about a version for one repository
    # * Files: ki-version.json, ki-statuses.json, ki-reverse-dependencies.json
    # @see Component
    # @see VersionMetadataFile
    # @see VersionStatusFile
    # @see KiJSONListFile
    class Version < DirectoryBase
      attr_chain :version_id, :require
      attr_chain :metadata, -> {VersionMetadataFile.new("ki-version.json").json_default("version_id" => version_id).parent(self)}

      def statuses
        VersionStatusFile.new("ki-statuses.json").parent(self)
      end

      def reverse_dependencies
        KiJSONListFile.new("ki-reverse-dependencies.json").parent(self)
      end

      def action_usage

      end
    end

    # Contains information about a component for one repository
    # * Files: ki-versions.json, status_info.json
    # @see Version
    # @see Repository
    class Component < DirectoryBase
      attr_chain :component_id, :require
      DirectoryWithChildrenInListFile.add_list_file(self, Version)

      # Chronological list of versions in this component
      class VersionListFile
        undef create_list_item
        def create_list_item(item)
          id = item["id"]
          Version.new(id).version_id(File.join(parent.component_id, id)).parent(parent)
        end

        def add_version(id, time=Time.now)
          obj = {"id" => id, "time" => time}
          edit_data do
            @cached_data.unshift obj
          end
          create_list_item(obj)
        end
      end

      # Status information file. Hash that defines information about status fields
      # * list defines order of statuses {"maturity": ["alpha","beta","gamma"]}
      def status_info
        KiJSONHashFile.new("status_info.json").parent(self)
      end
    end

    # Repository root
    # * Files: ki-components.json
    # @see Component
    class Repository < DirectoryBase
      attr_chain :repository_id, :require
      DirectoryWithChildrenInListFile.add_list_file(self, Component)

      # finds version matching the last part of version string, for example: my/component/1 looks for version named 1
      # @see Component#version
      def version(str)
        args = str.split("/")
        args.delete_at(-1)
        component(args.join("/")).version(str)
      end
    end
  end
end

