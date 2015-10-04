module SparkleMotion
  module Audio
    # Class to track signal processing info, and report on it in a readable way.
    class StreamReporter < Task
      # Tiny helper just to let us do things like:
      #   some_metric.average[channel]
      # ... without having to vivify the average in advance.
      class Averager
        def initialize(sums, counts)
          @sums   = sums
          @counts = counts
        end

        def [](channel); @sums[channel] / @counts[channel]; end
      end

      # Records metrics about a particular measurement for each channel.
      class Metric
        def initialize
          @mins     = []
          @maxes    = []
          @sums     = []
          @currents = []
          @counts   = []
          @averager = Averager.new(@sums, @counts)
        end

        def min; @mins; end
        def max; @maxes; end
        def current; @currents; end
        def mean; @averager; end

        def length; @currents.length; end

        def []=(channel, val)
          @mins[channel]   ||= Float::INFINITY
          @mins[channel]     = val if val < @mins[channel]
          @maxes[channel]  ||= 0.0
          @maxes[channel]    = val if val > @maxes[channel]
          @sums[channel]   ||= 0.0
          @sums[channel]    += val
          @counts[channel] ||= 0.0
          @counts[channel]  += 1
          @currents[channel] = val
        end
      end

      attr_reader :name, :dc0, :minima, :maxima, :sum, :mean, :count, :dropped_frames

      def initialize(stream_name, interval, logger)
        @name           = stream_name
        @interval       = interval

        reset!

        super("StreamReporter", logger) do
          next if count == 0

          print_report

          sleep @interval
        end
      end

      def print_report
        title = "%s[%05d, %05d]:" % [@name, @count, @dropped_frames]
        @logger.info { title }
        (0..@max_channel).each do |ch|
          print_channel(ch)
        end
      end

      def record_channel(channel:, datum:)
        @dc0[channel] = datum[:dc0]
        @metrics.each do |name, metric|
          metric[channel] = datum.fetch(name)
        end
      end

      def record(dropped_frames:, data:)
        @dropped_frames = dropped_frames
        data.each_with_index do |datum, index|
          record_channel(channel: index, datum: datum)
        end
        @max_channel = data.length - 1
        @count += 1
      end

      def reset!
        @dc0      = []
        @labels   = { min:    "Smallest Bin",
                      max:    "Largest Bin",
                      mean:   "Mean of Bins",
                      median: "Median of Bins",
                      sum:    "Sum of Bins",
                      rms:    "RMS" }
        @metrics  = Hash[@labels.keys.map { |name| [name, Metric.new] }]

        @count = @dropped_frames = @max_channel = 0
      end

    protected

      REPORT_FORMAT = "%-5s %15s: %10.1f <= %10.1f <= %10.1f"

      def print_channel(chan)
        @logger.info { "> Channel ##{chan}:" }
        @metrics.each do |name, mm|
          label = @labels[name]
          @logger.info { REPORT_FORMAT % [">", label, mm.min[chan], mm.mean[chan], mm.max[chan]] }
        end
      end
    end
  end
end
