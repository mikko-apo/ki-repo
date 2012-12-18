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
  module RepositoryMethods
    DirectoryWithChildrenInListFile.add_list_file(self, Repository::Repository)

    class RepositoryListFile
      undef :create_list_item
      def create_list_item(item)
        Repository::Repository.new("info/" + item).parent(parent).repository_id(item)
      end
    end

    def finder
      RepositoryFinder.new(self)
    end

    def version(*args, &block)
      finder.version(*args, &block)
    end
  end

  class KiHome < DirectoryBase
    include RepositoryMethods
    DirectoryWithChildrenInListFile.add_list_file(self, Repository::Repository, "package")
  end
end