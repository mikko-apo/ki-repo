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

require 'monitor'

module Ki
  class ServiceRegistry < Hash
    def initialize
      @monitor = Monitor.new
      @by_parent = {}
    end

    def register(*args)
      @monitor.synchronize do
        case args.size
          when 1
            args.first.each_pair do |url, clazz|
              register(url, clazz)
            end
          when 2
            url, clazz = args
            self[url]=clazz
            (@by_parent[File.dirname(url)]||=Array.new) << args
          else
            raise "Not supported '#{args.inspect}'"
        end
      end
      self
    end

    def find(url, value=nil)
      @monitor.synchronize do
        if include?(url)
          self[url]
        elsif @by_parent.include?(url)
          services = @by_parent[url]
          if services
            if value
              services = services.select { |id, service| service.supports?(value) }
            end
            services = ServiceList.new.concat(services)
          end
          services
        end
      end
    end

    def find!(url, value=nil)
      found = find(url, value)
      if found.nil?
        raise "Could not resolve '#{url}'"
      end
      found
    end

    def clear
      @monitor.synchronize do
        @by_parent.clear
        super
      end
    end

    class ServiceList < Array
      def services
        map { |url, service| service }
      end

      def service_names
        map { |url, service| File.basename(url) }
      end
    end
  end
end