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

require 'spec_helper'

describe KiCommand do
  before do
    @tester = Tester.new
  end
  after do
    @tester.after
  end

  it "should support pluggable commands" do
    original_commands = KiCommand::CommandRegistry.dup
    @tester.cleaners << lambda do
      KiCommand::CommandRegistry.clear
      KiCommand::CommandRegistry.register(original_commands)
    end
    class TestCommand

    end
    TestCommand.any_instance.expects(:execute).with {|ki_command, params| params.should == ["123","456"]}
    TestCommand.any_instance.expects(:help).returns("Help")
    KiCommand.register_cmd("test-command", TestCommand)
    KiCommand.new.execute(["test-command","123","456"])
    @tester.catch_stdio do
      KiCommand.new.execute(["help","test-command"])
    end.stdout.join.should =~ /Help/
  end

  it "should list available commands" do
    original_commands = KiCommand::CommandRegistry.dup
    @tester.cleaners << lambda do
      KiCommand::CommandRegistry.clear
      KiCommand::CommandRegistry.register(original_commands)
    end
    class TestCommand

    end
    KiCommand.register_cmd("test-command", TestCommand)
    TestCommand.any_instance.expects(:summary).returns("Test command is for testing")
    @tester.catch_stdio do
      KiCommand.new.execute(["commands"])
    end.stdout.join.should =~ /Test command is for testing/
  end

end