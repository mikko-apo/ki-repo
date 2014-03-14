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
  module KiEnumerable
    def size!(*args)
      args.each do |valid_size|
        if valid_size.kind_of?(Range)
          if valid_size.include?(size)
            return self
          end
        elsif valid_size.respond_to?(:to_i)
          if Integer(valid_size) == size
            return self
          end
        else
          raise "'#{valid_size.inspect}' not supported, needs to be either Range or have .to_i method"
        end
      end
      raise "size #{size} does not match '#{args.map { |s| s.to_s }.join("', '")}'"
    end

    def any_matches?(value)
      each do |pattern|
        if value.match(pattern)
          return pattern
        end
      end
      false
    end

    def find_first(count=1, &block)
      ret = []
      each do |item|
        if block.nil? || block.call(item)
          ret << item
          if ret.size == count
            break
          end
        end
      end
      if count==1
        ret.at(0)
      else
        ret
      end
    end

    def separate_to_hash(separator=nil, &block)
      ret = {}
      each do |item|
        if separator
          key, *values = item.split(separator)
          if values.size > 0 || item.include?(separator)
            ret[key]=values.join(separator)
          else
            ret[key]=true
          end
        elsif block
          key, value = block.call(item)
          ret[key]=value
        end
      end
      ret
    end

  end
end

class Array
  include Ki::KiEnumerable
end

module Enumerable
  include Ki::KiEnumerable
end

require 'fileutils'
class File
  def File.safe_write(dest, txt=nil, &block)
    tmp = dest + "-" + rand(99999).to_s
    begin
      File.open(tmp, "w") do |file|
        if block
          block.call(file)
        elsif txt
          file.write(txt)
        end
      end
      FileUtils.mv(tmp, dest)
    rescue Exception
      FileUtils.remove_entry_secure(tmp)
      raise
    end
  end
end

class Hash
  def require(key)
    if !include?(key)
      raise "'#{key}' is not defined!"
    end
    self[key]
  end
end

class Object
  # if block raises an exception outputs the error message. returns block's exit value or reraises the exception
  def show_errors(&block)
    begin
      block.call
    rescue Exception => e
      puts "Exception '#{e.message}':\n#{e.backtrace.join("\n")}"
      raise
    end
  end

  # Resolves fully qualified class named including modules: Ki::KiCommand
  def Object.const_get_full(full_class_name)
    class_or_module = self
    full_class_name.split("::").each do |name|
      class_or_module = class_or_module.const_get(name)
    end
    class_or_module
  end

  def try(retries, retry_sleep, &block)
    c = 0
    start = Time.now
    begin
      block.call(c+1)
    rescue Exception => e
      c += 1
      if c < retries
        sleep retry_sleep
        retry
      else
        raise e.class, e.message + " (tried #{c} times, waited #{sprintf("%.2f", Time.now - start)} seconds)", e.backtrace
      end
    end
  end
end

class String
  def split_strip(separator=",")
    split(separator).map { |s| s.strip }
  end
end

module ObjectSpace
  def ObjectSpace.all_classes
    arr = []
    each_object do |o|
      if o.kind_of?(Class)
        arr << o
      end
    end
    arr
  end
end
