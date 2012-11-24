require 'thread'

# ExceptionCatcher makes it easy to execute multiple operations even though any might fail with exception
# * executed tasks can be named to make it easier to identify which tasks failed
# * collects result and exceptions for each executed task
# * raises a {MultipleExceptions} exception if there were more than one exception
#
#    catcher = ExceptionCatcher.new
#    catcher.catch(1){raise "1"}
#    catcher.catch(2){raise "2"}
#    catcher.catch(3){"ok!"}
#    catcher.exception(1) # -> exception object raised by the task 1
#    catcher.exception(2) # -> exception object raise by the task 2
#    catcher.result(3) # -> "ok!"
#    catcher.check # raises a MultipleExceptions exception
#
class ExceptionCatcher
  attr_reader :tasks, :results, :exceptions, :mutex

  def initialize
    @mutex = Mutex.new
    @results = {}
    @exceptions = {}
    @tasks = []
  end

  # Catches exceptions thrown by block
  # @param [Object, nil] task if task is defined, results can be checked per task
  # @param [Proc] block, block which is executed
  # @return [Object, nil] returns block's result or nil if block raised an exception
  def catch(task=nil, &block)
    if task.nil?
      task = block
    end
    @mutex.synchronize do
      @tasks << task
    end
    begin
      result = block.call
      @mutex.synchronize do
        @results[task]=result
      end
      result
    rescue Exception => e
      @mutex.synchronize do
        @exceptions[task]=e
      end
      nil
    end
  end

  # @param [Object] task identifies the executed task
  # @return [Object,nil] result for the named block or nil if the block ended in exception
  def result(task)
    @mutex.synchronize do
      @results[task]
    end
  end

  # @param [Object] task identifies the executed task
  # @return [Object,nil] block's exception or nil if the block did not raise an exception
  def exception(task)
    @mutex.synchronize do
      @exceptions[task]
    end
  end

  # @return [bool] exceptions? returns true if there has been exceptions
  def exceptions?
    @exceptions.size > 0
  end

  # Checks if there has been exceptions and raises the original exception if there has been one exception and {MultipleExceptions} if there has been many exceptions
  def check
    @mutex.synchronize do
      if @exceptions.size == 1
        e = @exceptions.values.first
        raise e.class, e.message, e.backtrace
      elsif @exceptions.size > 1
        raise MultipleExceptions.new("Caught #{@exceptions.size} exceptions!").catcher(self)
      end
    end
  end

  # {ExceptionCatcher} raises MultipleExceptions if it has caught multiple exceptions.
  # MultipleExceptions makes the {ExceptionCatcher} and its results available
  class MultipleExceptions < RuntimeError
    include Enumerable
    # Reference to original {#ExceptionCatcher}
    attr_chain :catcher, :require
    # Map of exceptions
    attr_chain :exceptions, -> { catcher.exceptions }
    # Map of tasks that have been scheduled
    attr_chain :tasks, -> { catcher.tasks }

    def each(&block)
      exceptions.values.each(&block)
    end
  end
end


