module SparkleMotion
  module Audio
    # Class to track signal processing info, and report on it in a readable way.
    class StreamReporter < Task
      attr_reader :name, :dc0, :minima, :maxima, :mean, :count, :dropped_frames

      def initialize(stream_name, interval, logger)
        @name           = stream_name
        @interval       = interval

        initialize_vars!

        super("StreamReporter", logger) do
          next if count == 0

          print_report

          sleep @interval
        end
      end

      REPORT_FORMAT = "%30s %10.1f <= %10.1f <= %10.1f (dc0=%s)"

      def print_report
        title = "%s[%05d, %05d]:" % [@name, @count, @dropped_frames]
        (0..@max_channel).each do |ch|
          print_channel((ch == 0) ? title : "", ch)
        end
      end

      def record_channel(channel:, datum:)
        ensure_size(channel)
        @dc0[channel]     = datum[:dc0]
        @minima[channel]  = min(datum[:mean], @minima[channel])
        @maxima[channel]  = max(datum[:mean], @maxima[channel])
        @mean[channel]    = datum[:mean]
      end

      def record(dropped_frames:, data:)
        @dropped_frames = dropped_frames
        @max_channel    = data.length - 1
        data.each_with_index do |datum, index|
          record_channel(channel: index, datum: datum)
        end
        @count += 1
      end

      def reset!
        @count       = 0
        @max_channel = 0
        @minima      = []
        @maxima      = []
      end

    protected

      def initialize_vars!
        @dc0    = []
        @minima = []
        @maxima = []
        @mean   = []

        @count = @dropped_frames = @max_channel = 0
      end

      def min(a, b); (a < b) ? a : b; end
      def max(a, b); (a > b) ? a : b; end

      def ensure_size(channel)
        @minima[channel] ||= Float::INFINITY
        @maxima[channel] ||= 0.0
      end

      def print_channel(pref, chan)
        @logger.info { REPORT_FORMAT % [pref, minima[chan], mean[chan], maxima[chan], dc0[chan]] }
      end
    end
  end
end
