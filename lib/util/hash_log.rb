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
  # Generate hash object based log entries.
  # @see log
  module HashLog

    module Logged
      def logged

      end
    end

    HashLogThreadCurrentKey = :hash_log
    HashLogMutex = Mutex.new

    # Create a hash log entry or return current hash log entry
    # * Supports hierarchic logs, where log entry can contain any number of sub entries
    # * Supports parallel execution, threads can log in to one log structure
    # * Logs start and stop time of execution
    #
    # Hierarchic logging works by keeping a stack of log entries in Thread local store
    #
    # @see set_hash_log_root_for_thread
    # @see hash_log_current
    def log(*args, &block)
      current_log_entry = hash_log_current
      # return
      if args.empty? && block.nil?
        current_log_entry
      else
        new_entry = {"start" => Time.now.to_f}
        if args.first.kind_of?(String)
          new_entry["name"] = args.delete_at(0)
        end
        if args.first.kind_of?(Hash)
          new_entry.merge!(args.first)
        end
        log_list = nil
        if current_log_entry
          # there is current log entry, create a new sub log entry
          HashLogMutex.synchronize do
            log_list = current_log_entry["logs"] ||= []
          end
        else
          # append new_entry to end of log list
          log_list = Thread.current[HashLogThreadCurrentKey]
        end
        HashLogMutex.synchronize do
          log_list << new_entry
        end
        if block
          HashLogMutex.synchronize do
            Thread.current[HashLogThreadCurrentKey] << new_entry
          end
          begin
            block.call new_entry
          rescue Exception => e
            new_entry["exception"] = e.message
            if !defined? e.logged
              new_entry["backtrace"] = e.backtrace.join("\n")
              e.extend(Logged)
            end
            raise
          ensure
            HashLogMutex.synchronize do
              Thread.current[HashLogThreadCurrentKey].delete(new_entry)
            end
            new_entry["end"] = Time.now.to_f
          end
        else
          new_entry
        end
      end
    end

    def set_hash_log_root_for_thread(root)
      HashLogMutex.synchronize do
        (Thread.current[HashLogThreadCurrentKey] ||= []) << root
      end
    end

    def hash_log_current
      HashLogMutex.synchronize do
        (Thread.current[HashLogThreadCurrentKey] ||= []).last
      end
    end
  end
end