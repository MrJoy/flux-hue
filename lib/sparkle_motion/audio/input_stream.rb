module SparkleMotion
  module Audio
    # Abstract base class for input stream reader that pushes data into a `Queue`.
    #
    # When data is finished, `nil` is pushed onto the queue.
    class InputStream
      attr_reader :queue, :name, :sample_rate, :window
      def initialize(window)
        @queue        = Queue.new
        @stop_signal  = false
        @window       = window
        @input_thread = create_input_thread
      end

      def dropped_frames; fail "Must be implemented by sub-class!"; end
      def start; @input_thread.run; end
      def pop; @queue.pop; end
      def finite?; fail "Must be implemented by sub-class!"; end

      def stop
        @stop_signal = true
        @input_thread.join
      end

    protected

      def create_input_thread
        Thread.new do
          Thread.stop
          loop do
            data = @input.read(window)
            break if @stop_signal || data.nil?
            queue.push(data)
          end

          queue.push(nil)
        end
      end
    end
  end
end
