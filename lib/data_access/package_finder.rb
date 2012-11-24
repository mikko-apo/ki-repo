module Ki
# Collects all components from all package info directories
  class PackageFinder
    attr_reader :versions

    def initialize(source)
      @components = load_all_components(source)
      @versions = HashCache.new
    end

    def load_all_components(source)
      components = HashCache.new
      node = source
      while (node)
        node.package_infos.each do |info|
          info.components.each do |component_info|
            component = components.cache(component_info.component_id) do
              Component.new.component_id(component_info.component_id).package_collector(self).components([])
            end
            component.components << component_info
          end
        end
        if node.root?
          node = nil
        else
          node = node.parent
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

    def has_statuses(version_statuses_original, status_rules, component)
      ret = true
      if status_rules.size > 0
        ret = false
        version_statuses = version_statuses_original.reverse # latest first
        status_info = component.status_info
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

    def component(component)
      @components[component]
    end

    def version(*args, &block)
      status_rules = []
      component_or_version = nil
      args.each do |str|
        if str.kind_of?(String)
          strings = str.split(":")
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
        component.version_by_id(version_name)
      else
        nil
      end
    end
  end
end
