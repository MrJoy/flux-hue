module SparkleMotion
  module Audio
    # Abstract base class for sending a stream of audio data somewhere.
    class OutputStream
      attr_reader :name, :sample_rate, :window

      def initialize(rate, window)
        @window = window
        fail "Input and output have different sample rates!" if @sample_rate != rate
      end

      def write(_val); fail "Must be implemented by sub-class!"; end
      def start; fail "Must be implemented by sub-class!"; end
      def stop; fail "Must be implemented by sub-class!"; end
    end
  end
end
