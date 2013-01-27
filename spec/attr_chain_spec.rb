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

require 'spec_helper'

describe "attr_chain" do
  it "should set, chain set and get values" do
    class Foo
      attr_chain :bar
    end
    f = Foo.new
    f.bar.should eq(nil)
    f.bar=1
    f.bar.should eq(1)
    f.bar(2)
    f.bar.should eq(2)
    f.bar(1).bar(3).bar.should eq(3)
  end

  it "should set default value with proc" do
    class Foo
      attr_chain :bar, -> { "a" }
    end
    Foo.new.bar.should eq("a")
  end

  it "default value should be resolved within object's context" do
    class Foo
      attr_chain :bar, -> { my_method("1") }

      def my_method(arg)
        "test-#{arg}"
      end
    end
    Foo.new.bar.should eq("test-1")
  end

  it ":require should require value to be set" do
    class Foo
      attr_chain :bar, :require
      attr_chain :baz, :require => "You need to set baz"
    end
    f = Foo.new
    lambda { f.bar }.should raise_error("'bar' has not been set")
    lambda { f.baz }.should raise_error("'baz' has not been set: You need to set baz")
    f.bar=1
    f.bar.should eq(1)
  end

  it ":immutable attr should allow value to be set only once" do
    class Foo
      attr_chain :bar, :immutable
    end
    f = Foo.new
    f.bar.should eq(nil)
    f.bar=1
    f.bar.should eq(1)
    lambda { f.bar=2 }.should raise_error("'bar' has been set once already")
  end

  it "should manage to arrays correctly" do
    class Foo
      attr_chain :bar
    end
    f=Foo.new
    f.bar= [1, 2]
    f.bar.should eq([1, 2])
    f.bar= [[1, 2]]
    f.bar.should eq([[1, 2]])
    f.bar([1, 2]).bar.should eq([1, 2])
    f.bar(1, 2).bar.should eq([1, 2])
    f.bar([[1, 2]]).bar.should eq([[1, 2]])
  end

  it ":valid should warn about invalid values" do
    class Foo
      attr_chain :bar, ["a", 1, lambda { |v| v=="test" }, lambda { |v| v.bar==1 }]
    end
    f=Foo.new
    f.bar("a").bar.should eq("a")
    f.bar(1).bar.should eq(1)
    f.bar("test").bar.should eq("test")
    Foo.new.bar(f.bar(1)).bar.bar.should eq(1)
    lambda { Foo.new.bar(f.bar("a")) }.should raise_error("invalid value for 'bar'")
    lambda { Foo.new.bar(2) }.should raise_error("undefined method 'bar' for 2:Fixnum")
  end

  it "should accept long configuration syntax" do
    class Foo
      attr_chain :default, :default => -> { "b" }
      attr_chain :immutable, :immutable => true
      attr_chain :require, :require => true
      attr_chain :valid, :valid => ["a"]
      attr_chain :valid_short, :valid => lambda { |s| raise "valid_test has been set already" if defined? @valid_test }
      attr_chain :valid_test
    end
    f = Foo.new
    f.default.should eq("b")
    f.immutable(1).immutable.should eq(1)
    lambda { f.immutable=2 }.should raise_error("'immutable' has been set once already")
    lambda { f.require }.should raise_error("'require' has not been set")
    f.require(1).require.should eq(1)
    f.valid="a"
    lambda { f.valid=2 }.should raise_error("invalid value for 'valid'")
    # tests that defining :valid as single item works and that the lambda can access the correct context
    f.valid_short("a").valid_short.should eq("a")
    f.valid_test(1)
    lambda { f.valid_short("b") }.should raise_error("valid_test has been set already")
  end

  it "should convert values" do
    class Foo
      attr_chain :converted, :convert => ->(s) { s+1 }
      attr_chain :converted_2, :convert => lambda { |s| s+2 }
    end
    f = Foo.new
    f.converted(1).converted.should eq(2)
    f.converted_2(1).converted_2.should eq(3)
  end

  it "should provide accessor to edit other than local fields" do
    class TestAccessor
      def get(object, name)
        object.cached_data[name]
      end

      def set(object, name, value)
        object.cached_data[name] = value
      end

      def defined?(object, name)
        object.cached_data.include?(name)
      end
    end
    class Foo
      attr_chain :cached_data, -> { Hash.new }
      attr_chain :name, :require, :accessor => TestAccessor.new
      attr_chain :email, -> { "test@email.fi" }, :accessor => TestAccessor.new
    end
    f = Foo.new
    f.email.should eq("test@email.fi")
    f.cached_data.keys.should eq([:email])
    f.email = "test"
    f.email.should eq("test")
    lambda { f.name }.should raise_error(RuntimeError, "'name' has not been set")
    f.name="foo"
    f.cached_data.should eq({:email=>"test", :name=>"foo"})
  end

  it "should support modules" do
    module Bar
      attr_chain :foo, -> { "bar" }
    end
    class Foo
      include Bar
    end
    class Zap

    end
    Foo.new.foo.should eq("bar")
    zap = Zap.new
    zap.extend(Bar)
    zap.foo.should eq("bar")
  end

  it "should raise errors on different usecases" do
    lambda {
      class UnsupportedParameterType
        attr_chain :bad, 1
      end
    }.should raise_error(RuntimeError, "attr_chain :bad unsupported parameter: '1'")
    lambda {
      class DoubleDefinition
        attr_chain :bad, [], [1]
      end
    }.should raise_error(RuntimeError, "attr_chain :bad, :valid was already defined to '[]' (new value: '[1]')")
    lambda {
      class BadDefault
        attr_chain :bad, :default => 1
      end
    }.should raise_error(RuntimeError, "attr_chain :bad, :default needs to be a Proc, not '1'")
    lambda {
      class BadConvert
        attr_chain :bad, :convert => 1
      end
    }.should raise_error(RuntimeError, "attr_chain :bad, :convert needs to be a Proc, not '1'")
    lambda {
      class BadParameter
        attr_chain :bad, :badparameter => 1
      end
    }.should raise_error(RuntimeError, "attr_chain :bad unsupported parameter: ':badparameter'")
  end
end


