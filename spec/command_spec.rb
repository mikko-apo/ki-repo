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
    TestCommand.any_instance.expects(:execute).with(["123","456"])
    TestCommand.any_instance.expects(:help).returns("Help")
    KiCommand.register_cmd("test-command", TestCommand)
    KiCommand.new.execute(["test-command","123","456"])
    @tester.catch_stdio do
      KiCommand.new.execute(["help","test-command"])
    end.stdout.join.should == "Help\n"
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
