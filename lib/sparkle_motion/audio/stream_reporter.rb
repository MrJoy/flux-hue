module SparkleMotion
  module Audio
    # Class to track signal processing info, and report on it in a readable way.
    class StreamReporter
      attr_reader :name, :dc0, :min, :max, :mean, :count, :dropped_frames

      def initialize(stream_name)
        @name           = stream_name
        @dc0            = []
        @min            = []
        @max            = []
        @mean           = []
        @count          = 0
        @dropped_frames = 0
        @max_channel    = 0
      end

      REPORT_FORMAT = "%30s %10.1f <= %10.1f <= %10.1f (dc0=%s)"

      def print_report(logger)
        title = "%s[%05d, %05d]:" % [@name, @count, @dropped_frames]
        (0..@max_channel).each do |ch|
          print_channel(logger, (ch == 0) ? title : "", ch)
        end
      end

      def record_channel(channel:, dc0:, mean:)
        @dc0[channel]     = dc0
        @min[channel]   ||= Float::INFINITY
        @min[channel]     = mean if mean < min[channel]
        @max[channel]   ||= 0.0
        @max[channel]     = mean if mean > max[channel]
        @mean[channel]    = mean
      end

      def record(dropped_frames:, channels:)
        @dropped_frames   = dropped_frames
        @max_channel      = channels - 1
        @count           += 1
      end

      def start((logger, interval))
        @end_signal       = false
        @reporting_thread = create_thread(logger, interval)
      end

      def stop
        @end_signal = true
        @reporting_thread.join
      end

      def reset!
        @count       = 0
        @max_channel = 0
        @min         = []
        @max         = []
      end

    protected

      def print_channel(logger, prefix, chan)
        logger.info { REPORT_FORMAT % [prefix, min[chan], mean[chan], max[chan], dc0[chan]] }
      end

      def create_thread(logger, interval)
        Thread.new do
          loop do
            break if @end_signal
            next if count == 0

            print_report(logger)

            sleep interval
          end
        end
      end
    end
  end
end
