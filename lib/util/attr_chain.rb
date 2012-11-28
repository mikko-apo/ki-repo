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

# Attaches configurable behaviour to accessor methods
#
#   class Foo
#      attr_chain :name, :require
#      attr_chain :email, -> {""}
#      attr_chain :birth_day, :immutable, :valid => lambda { |i| (1870..Time.now.year+1).include?(i) }, :require => true
#      attr_chain :children, :convert => lambda {|s| s.to_i}
#   end
#
# Sets up public methods variable_name and variable_name= which both can be used to access the fields. Giving any parameters
# for the method makes it a "set" operation and giving no parameters makes it a "get" operation. "Set" stores the value
# and returns self, so set calls can be chained. "Get" returns the stored value.
#
#    foo.email("test@email.com").name("test")
#    foo.email => "test@email.com"
#    foo.name => "test"
#
# Parameters can be given in short and long format. Short format works by identifying parameter types,
# long format works by given the name and value as hash parameters:
# * <tt>:require=>"You need to define xxx first"</tt>, <tt>:require=>true</tt>, short: <tt>:require</tt> - an exception is thrown if target field is not defined
# * <tt>:default=> -> {true}</tt>, short: <tt>-> {Array.new}</tt> - if target field has not been defined, executes proc and stores value. proc is executed using object.instance_exec: object's fields & methds are available
# * <tt>:immutable=>true</tt>, short: <tt>:immutable</tt> - an exception is thrown if target field is defined a second time
# * <tt>:valid=>[1,2,3,"a", lambda {|s| s.include?("b")}]</tt>, <tt>:valid => lambda {|s| s.include?("b")}</tt>, short: <tt>[1,2,3,"a"]</tt> - List of valid values. If any matches, sets value. If none matches, raises exception. Long form wraps single arguments to a list.
# * <tt>:convert=> ->(s) { s+1 }</tt> - Converts input value using the defined proc
# * <tt>:accessor=>InstanceVariableAccessor.new</tt> - Makes it possible to set values in other source, for example a hash. By default uses InstanceVariableAccessor
#
# Advantages for using attr_chain
# * attr_chain has a compact syntax for many important programming concepts -> less manually written boilerplate code is needed
# * :default makes it easy to isolate functionality to a default value while still making it easy to override the default behaviour
# * :default adds easy lazy evalution and memoization to the attribute, default value is evaluated only if needed
# * Testing becomes easier when objects have more exposed fields
# * :require converts tricky nil exceptions in to useful errors. Instead of the "undefined method `bar' for nil:NilClass" you get a good error message that states which field was not defined
#      foo.name.bar # if name has not been defined, raises "'name' has not been set" exception
# * :immutable, :valid and :convert make complex validations and converts easy
#
# Warnings about attr_chain
# * Performance has not been measured and attr_chain is probably not efficient. If there are tight inner loops, it's better to cache the value and store it afterwards
# * There has not been tests for memory leaks. It's plain ruby so GC should take care of everything
# * Excessive attr_chain usage makes classes a mess. Try to keep your classes short and attr_chain count below 10.
# @see InstanceVariableAccessor
# @see Object.attr_chain
# @see Module#attr_chain
class AttrChain
  # Parses parameters with parse_short_syntax and set_parameters and configures class methods
  # * each attr_chain definition uses one instance of AttrChain which holds the configuration for the definition
  # * Object::define_method is used to add two methods to target class and when called both of these methods call attr_chain with their parameters
  # @see Object.attr_chain
  # @see Module#attr_chain
  def initialize(clazz, variable_name, attr_configs)
    @variable_name = variable_name
    @accessor = InstanceVariableAccess
    set_parameters(variable_name, parse_short_syntax(variable_name, attr_configs))
    me = self
    attr_call = lambda { |*args| me.attr_chain(self, args) }
    [variable_name, "#{variable_name}="].each do |method_name|
      clazz.send(:define_method, method_name, attr_call)
    end
  end

  # Converts short syntax entries in attr_configs to long syntax
  # * warns about not supported values and already defined values
  def parse_short_syntax(variable_name, attr_configs)
    params = {}
    attr_configs.each do |attr_config|
      key_values = if [:require, :immutable].include?(attr_config)
                     [[attr_config, true]]
                   elsif attr_config.kind_of?(Proc)
                     [[:default, attr_config]]
                   elsif attr_config.kind_of?(Array)
                     [[:valid, attr_config]]
                   elsif attr_config.kind_of?(Hash)
                     all = []
                     attr_config.each_pair do |pair|
                       all << pair
                     end
                     all
                   else
                     raise "attr_chain :#{variable_name} unsupported parameter: '#{attr_config.inspect}'"
                   end
      key_values.each do |key, value|
        if params.include?(key)
          raise "attr_chain :#{variable_name}, :#{key} was already defined to '#{params[key]}' (new value: '#{value}')"
        end
        params[key]=value
      end
    end
    params
  end

  # Parses long syntax values and sets configuration for this field
  def set_parameters(variable_name, params)
    params.each_pair do |key, value|
      case key
        when :require
          @require = value
        when :default
          if !value.kind_of?(Proc)
            raise "attr_chain :#{variable_name}, :default needs to be a Proc, not '#{value.inspect}'"
          end
          @default = value
        when :immutable
          @immutable = value
        when :valid
          if !value.kind_of?(Array)
            value = [value]
          end
          value.each do |valid|
            if valid.kind_of?(Proc)
              @valid_procs ||= []
              @valid_procs << valid
            else
              @valid_items ||= {}
              @valid_items[valid]=valid
            end
          end
        when :convert
          if !value.kind_of?(Proc)
            raise "attr_chain :#{variable_name}, :convert needs to be a Proc, not '#{value.inspect}'"
          end
          @convert = value
        when :accessor
          @accessor = value
        else
          raise "attr_chain :#{variable_name} unsupported parameter: '#{key.inspect}'"
      end
    end
  end

  # Handles incoming methods for "get" and "set"
  # * called by methods defined to class
  # * configuration is stored as instance variables, the class knows which variable is being handled
  # * method call parameters come as list of parameters
  def attr_chain(object, args)
    if args.empty?
      if !@accessor.defined?(object, @variable_name)
        if @default
          @accessor.set(object, @variable_name, object.instance_exec(&@default))
        elsif @require
          if @require.kind_of?(String)
            raise "'#{@variable_name}' has not been set: #{@require}"
          else
            raise "'#{@variable_name}' has not been set"
          end
        end
      end
      @accessor.get(object, @variable_name)
    else
      if @immutable && @accessor.defined?(object, @variable_name)
        raise "'#{@variable_name}' has been set once already"
      end
      value_to_set = if args.size == 1
                       args.first
                     else
                       args
                     end
      if @convert
        value_to_set = object.instance_exec(value_to_set, &@convert)
      end
      if @valid_items || @valid_procs
        is_valid = false
        if @valid_items && @valid_items.include?(value_to_set)
          is_valid = true
        end
        if is_valid == false && @valid_procs
          @valid_procs.each do |valid_proc|
            if is_valid=object.instance_exec(value_to_set, &valid_proc)
              break
            end
          end
        end
        if is_valid == false
          raise "invalid value for '#{@variable_name}'"
        end
      end
      @accessor.set(object, @variable_name, value_to_set)
      object
    end
  end

  # Wrapper for Object::instance_variable_get, Object::instance_variable_set and Object::instance_variable_defined?
  class InstanceVariableAccessor
    def edit_name(variable_name)
      "@#{variable_name}".to_sym
    end

    def get(object, name)
      object.instance_variable_get(edit_name(name))
    end

    def set(object, name, value)
      object.instance_variable_set(edit_name(name), value)
    end

    def defined?(object, name)
      object.instance_variable_defined?(edit_name(name))
    end
  end

  InstanceVariableAccess = InstanceVariableAccessor.new

  class HashAccessor
    def get(object, name)
      object[name.to_s]
    end

    def set(object, name, value)
      object[name.to_s] = value
    end

    def defined?(object, name)
      object.include?(name.to_s)
    end
  end

  HashAccess = HashAccessor.new
end

class Object
  # Configurable accessor methods
  # @see AttrChain
  # @return [void]
  def self.attr_chain(variable_name, *attr_configs)
    AttrChain.new(self, variable_name, attr_configs)
  end
end

class Module
  # When a module defines an attr_chain, the attr_chain methods are available to all classes that are extended with the module
  # @see AttrChain
  # @return [void]
  def attr_chain(variable_name, *attr_configs)
    AttrChain.new(self, variable_name, attr_configs)
  end
end
