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
  module HashLog
    ThreadCurrentHashLogKey = :hash_log

    def log(*args, &block)
      current_log_entry = current_log
      if args.empty? && block.nil?
        current_log_entry
      else
        # there were parameters, create a new log entry
        if current_log_entry
          log_list = current_log_entry["logs"] ||= []
        else
          log_list = Thread.current[ThreadCurrentHashLogKey]
        end
        log_list << new_l = {"start" => Time.now}
        if args.first.kind_of?(String)
          new_l["name"] = args.delete_at(0)
        end
        if args.first.kind_of?(Hash)
          new_l.merge!(args.first)
        end
        if block
          Thread.current[ThreadCurrentHashLogKey] << new_l
          begin
            block.call new_l
          rescue Exception => e
            new_l["exception"] = e.message
            new_l["backtrace"] = e.backtrace.join("\n")
            raise
          ensure
            Thread.current[ThreadCurrentHashLogKey].delete(new_l)
            new_l["end"] = Time.now
          end
        else
          new_l
        end
      end
    end

    def thread_log_root(root)
      (Thread.current[ThreadCurrentHashLogKey] ||= []) << root
    end

    def current_log
      (Thread.current[ThreadCurrentHashLogKey] ||= []).last
    end
  end
end