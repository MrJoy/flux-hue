module SparkleMotion
  module Audio
    # Abstract base class for input stream reader that pushes data into a `Queue`.
    #
    # When data is finished, `nil` is pushed onto the queue.
    class InputStream < ManagedTask
      attr_reader :queue, :sample_rate, :window
      def initialize(name, window, logger)
        @queue  = Queue.new
        @window = window
        super(name, :early, logger) do
          data = @input.read(window)
          @end_signal = true if data.nil?
          queue.push([data, dropped_frames])
        end
      end

      def dropped_frames; fail "Must be implemented by sub-class!"; end
      def pop; @queue.pop; end
      def finite?; fail "Must be implemented by sub-class!"; end

      def stop
        super
        queue.push(nil)
      end
    end
  end
end
