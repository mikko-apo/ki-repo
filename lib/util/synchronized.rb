module Ki
  class SynchronizedArray
    attr_reader :array

    def initialize(arr = [])
      extend MonitorMixin
      @array = arr
    end

    def << item
      synchronize do
        @array << item
      end
    end

    def delete(item)
      synchronize do
        @array.delete(item)
      end
    end

    def dup
      synchronize do
        @array.dup
      end
    end

    def include?(item)
      synchronize do
        @array.include?(item)
      end
    end
  end
end