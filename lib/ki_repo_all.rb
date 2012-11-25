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

require 'bundler/setup'

require_relative 'util/attr_chain'
require_relative 'util/exception_catcher'
require_relative 'util/ruby_extensions'
require_relative 'util/test'
require_relative 'util/shell'
require_relative 'util/service_registry'
require_relative 'util/hash'
require_relative 'util/hash_cache'
require_relative 'util/simple_optparse'

require_relative 'data_storage/dir_base'
require_relative 'data_storage/ki_json'
require_relative 'data_storage/package_info'
require_relative 'data_storage/version_metadata'
require_relative 'data_storage/projects'

require_relative 'data_access/package_access'
require_relative 'data_access/package_finder'
require_relative 'data_access/version_commands'
require_relative 'data_access/version_operations'
require_relative 'data_access/version_finders'

require_relative 'cmd/cmd'
require_relative 'cmd/packages_cmd'
require_relative 'cmd/user_pref_cmd'
