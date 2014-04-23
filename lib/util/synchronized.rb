module Ki
  class SynchronizedArray
    attr_reader :list

    def initialize
      extend MonitorMixin
      @list = []
    end

    def << item
      synchronize do
        @list << item
      end
    end

    def delete(item)
      synchronize do
        @list.delete(item)
      end
    end

    def dup
      synchronize do
        @list.dup
      end
    end

    def include?(item)
      synchronize do
        @list.include?(item)
      end
    end
  end
end