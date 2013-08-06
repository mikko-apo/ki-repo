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

# Helper class for testing functionality that uses threads
# @example
#    l = ThreadLatch.new
#    thread {l.wait(:b); puts "b";l.tick(:c)}
#    thread {l.wait(:a); puts "a";l.tick(:b);l.tick(:c)}
#    l.tick(:a)
#    l.wait(:c, 2)
#    puts "c"
class ThreadLatch
  # Turns on debug printing
  attr_accessor :debug

  def initialize
    @lock = Mutex.new
    @cvs = {}
  end

  # Increments counter
  def tick(id=nil)
    @lock.synchronize do
      params = (@cvs[id] ||= [ConditionVariable.new, 0])
      params[1] = params.last + 1

      if @debug
        $stdout.flush
        puts "#{id} tick #{Thread.current.object_id} (count = #{params.last})"
        $stdout.flush
      end

      params.first.broadcast
    end
  end

  # Waits until counter reaches defined value
  # * value can be defined with constructor
  # @param [Object, nil] to To defines target count for wait. If nil and no to values has been given with constructor, to is set to 1
  # @param [Integer, nil] to To defines target count for wait. If nil and no to values has been given with constructor, to is set to 1
  def wait(id=nil, dest=nil)
    @lock.synchronize do
      if dest
        dest = dest.to_i
        raise ArgumentError, "cannot count down from negative integer #{dest}" if dest < 0
      else
        dest=1
      end
      loop = true
      while loop
        cv, count = (@cvs[id] ||= [ConditionVariable.new, 0])
        if count >= dest
          loop = false
          if @debug
            puts "#{id}.released #{Thread.current.object_id} (count = #{count}, dest = #{dest})"
          end
        else
          if @debug
            $stdout.flush
            puts "#{id}.wait #{Thread.current.object_id} (count = #{count}, dest = #{dest})"
            $stdout.flush
          end
          cv.wait(@lock)
        end
      end
    end
  end
end

describe HashLog do
  it "should log hierarchic events" do
    class Foo
      include HashLog
    end
    Time.expects(:now).returns(11, 22, 33, 44).times(4)
    f = Foo.new
    root = nil
    ret = f.log("a") do |l|
      root = l
      f.log("b", "test" => "bar") do
        1
      end
    end
    ret.should == 1
    root.should == {"start" => 11, "name" => "a", "logs" => [{"start" => 22, "name" => "b", "test" => "bar", "end" => 33}], "end" => 44}
  end
  it "should log parallel events" do
    Time.expects(:now).returns(11, 22, 33, 44, 55, 66).times(6)
    class Foo
      include HashLog
    end
    f = Foo.new
    latch = ThreadLatch.new
    root_log = nil
    f.log("root") do |l|
      root_log = l
      a = Thread.new do
        latch.wait(:b_ready)
        f.thread_log_root(l)
        f.log("a") do
        end
        latch.tick(:a_ready)
      end
      b = Thread.new do
        f.thread_log_root(l)
        f.log("b") do
          latch.tick(:b_ready)
          latch.wait(:a_ready)
        end
      end
      a.join
      b.join
    end
    root_log.should == {"start" => 11, "name" => "root", "logs" => [{"start" => 22, "name" => "b", "end" => 55}, {"start" => 33, "name" => "a", "end" => 44}], "end" => 66}
  end
end
