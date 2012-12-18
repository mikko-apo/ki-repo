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
  # Collects components from multiple repositories and provides methods to find components and versions
  # @see Component
  # @see Version
  class RepositoryFinder
    attr_reader :versions
    attr_reader :components

    def initialize(source)
      @source = source
      @components = load_all_components
      @versions = HashCache.new
    end

    # Finds matching component by name
    # @return [Component] matching component
    def component(component)
      @components[component]
    end

    # Finds version matching arguments, goes through versions in chronological order from latest to oldest.
    # * note: block form can be used to iterate through all available version
    # Supported search formats:
    # * version("test/comp") -> latest version
    # * version("test/comp:Smoke=green"), version("test/comp","Smoke"=>"green") -> latest version with matching status
    # * version("test/comp"){|version| ... } -> iterates all available versions and returns latest version where block returns true, block argument is a Version
    # * version("test/comp:maturity!=alpha") ->
    # Component can define ordering for status values: {"maturity": ["alpha","beta","gamma"]}
    # * version("test/comp:maturity>alpha") -> returns first version where maturity is beta or gamma
    # * version("test/comp:maturity>=alpha") -> returns first version where maturity is alpha, beta or gamma
    # * version("test/comp:maturity<beta") -> returns first version where maturity is alpha
    # * version("test/comp:maturity<=beta") -> returns first version where maturity is alpha or beta
    # Version supports also Component and Version parameters:
    # * version(my_version) -> returns my_version
    # * version(my_component, "Smoke:green") -> finds Version matching other parameters
    # @return [Version] matching version
    def version(*args, &block)
      if args.empty?
        raise "no parameters!"
      end
      status_rules = []
      component_or_version = nil
      dep_navigation_arr = []
      args.each do |str|
        if str.kind_of?(String)
          dep_nav_arr = str.split("->")
          strings = dep_nav_arr.delete_at(0).split(":")
          dep_navigation_arr.concat(dep_nav_arr)
          if component_or_version.nil?
            component_or_version = strings.delete_at(0)
          end
          strings.each do |s|
            status_rules << s.match(/(.*?)([<=>!]+)(.*)/).captures
          end
        elsif str.kind_of?(Hash)
          str.each_pair do |k, v|
            status_rules << [k, "=", v]
          end
        elsif str.kind_of?(Version)
          return str
        elsif str.kind_of?(Component) && component_or_version.nil?
          component_or_version = str.component_id
        else
          raise "Not supported '#{str.inspect}'"
        end
      end
      if component = @components[component_or_version]
        if status_rules.size > 0 || block
          component.versions.each do |v|
            ver = component.version_by_id(v.name)
            ok = has_statuses(ver.statuses, status_rules, component)
            if ok && block
              ok = block.call(ver)
            end
            if ok
              return ver
            end
          end
        else
          # picking latest version
          version_name = component.versions.first.name
        end
      else
        # user has defined an exact version
        version_arr = component_or_version.split("/")
        version_name = version_arr.delete_at(-1)
        component_str = version_arr.join("/")
        component = @components[component_str]
      end
      if component && version_name
        ver = component.version_by_id(version_name)
        if dep_navigation_arr
          dep_navigation_arr.each do |dep_str|
            dep_version_str = find_dep_by_name(ver, dep_str)
            if dep_version_str.nil?
              raise "Could not locate dependency '#{dep_str}' from '#{ver.version_id}'"
            end
            ver = version(dep_version_str)
          end
        end
        ver
      else
        nil
      end
    end

    def find_dep_by_name(ver, dep_str)
      ver.metadata.dependencies.each do |dep|
        if dep["name"] == dep_str
          return dep["version_id"]
        end
      end
      nil
    end

    def all_repositories(source=@source)
      node = source
      repositories = []
      while (node)
        repositories.concat(node.repositories.to_a)
        if node.root?
          break
        end
        node = node.parent
      end
      repositories
    end

    # Loads all Component from all repositories
    # @param [KiHome] source
    def load_all_components(source=@source)
      components = HashCache.new
      all_repositories(source).each do |info|
        info.components.each do |component_info|
          component = components.cache(component_info.component_id) do
            Component.new.component_id(component_info.component_id).finder(self).components([])
          end
          component.components << component_info
        end
      end
      components
    end

    # locates first matching status for the key and checks if that is ok for the block
    def check_status_value(version_statuses, key, &block)
      version_statuses.each do |status_key, status_value|
        if status_key == key
          return block.call(status_value)
        end
      end
      false
    end

    # Checks if version's statuses match status_rules
    def has_statuses(version_statuses_original, status_rules, component)
      ret = true
      if status_rules.size > 0
        ret = false
        version_statuses = version_statuses_original.reverse # latest first
        status_info = component.status_info
                                                             # go through each rule and see if this version has matching status
        status_rules.each do |key, op, value|
          if order = status_info[key]
            rule_value_index = order.index(value)
          end
          op_action = {
              "=" => ->(status_value) { status_value == value },
              "!=" => ->(status_value) { status_value != value },
              "<" => ->(status_value) { order.index(status_value) < rule_value_index },
              ">" => ->(status_value) { order.index(status_value) > rule_value_index },
              ">=" => ->(status_value) { order.index(status_value) >= rule_value_index },
              "<=" => ->(status_value) { order.index(status_value) <= rule_value_index }
          }.fetch(op) do
            raise "Not supported status operation: '#{key}#{op}#{value}'"
          end
          ret = check_status_value(version_statuses, key) do |status_value|
            op_action.call(status_value)
          end
        end
      end
      ret
    end
  end
end
