module SparkleMotion
  module Audio
    # Applies a filter to a stream, and optionally allows chaining the output to another stream.
    class StreamFilter < SparkleMotion::Task
      def initialize(stream, filter, logger, &handler)
        @filter   = filter
        @stream   = stream
        @window   = stream.window
        @handler  = handler
        super("StreamFilter", logger) { |frame, drop_count| process_frame(frame, drop_count) }
      end

      def send_to(channels, target)
        @from_channels  = channels
        @target         = target
      end

    protected

      def read_frame
        frame, drop_count = @stream.pop
        return false unless frame && frame.shape[1] == @window
        [frame, drop_count]
      end

      def normalize(frame); frame / frame.length; end

      def fft_forward(frame); NumRu::FFTW3.fft(frame, -1, 0); end
      def fft_backward(frame); NumRu::FFTW3.fft(frame, 1, 0); end

      def task_loop(&handler)
        loop do
          frame, drop_count = read_frame
          break unless frame
          handler.call(frame, drop_count)
          break if @end_signal
        end
      end

      # TODO: Actually check the device!
      def output_channels; 0..1; end

      def collect_data_for_output(snapshot)
        # TODO: Handle output channels that aren't continuous starting at 0.
        snapshot
          .zip(0..(snapshot.length - 1))
          .select { |(_data, channel)| @from_channels.include?(channel) }
          .slice(output_channels)
          .map(&:first)
      end

      def send(snapshot)
        return unless @target
        # TODO: Sanity-check that the number of output channels is sane for the output device,
        # TODO: that we're throwing acceptable data at it, etc.
        frame = NArray.new(snapshot.first.typecode, output_channels.size, @window)
        collect_data_for_output(snapshot)
          .map { |data| fft_backward(data) }
          .each_with_index do |data, channel|
            frame[channel, 0..-1] = data
          end
        @target.write(frame)
      end

      def process_frame(frame, drop_count)
        snapshot = []
        (0..(frame.shape[0] - 1)).each do |channel|
          channel_data  = frame[channel, 0..-1]
          data          = normalize(fft_forward(channel_data))

          debug_filter(channel, channel_data, data)
          @filter.apply!(data)
          debug_filter(channel, channel_data, data)

          snapshot << data
        end

        @handler.call(snapshot, drop_count) if @handler

        send(snapshot)
      end

    private

      def bounce(x); x < 0 ? @window + x : x; end
      def r_str(range)
        meh = (0..(@window - 1)).to_a[range]
        "#{bounce(meh.first)}..#{bounce(meh.last)}"
      end

      def debug_filter(_channel, _channel_data, data)
        $stdout.puts "<<<<<"
        high_pass_ranges  = @filter.send(:high_pass_ranges)
        low_pass_ranges   = @filter.send(:low_pass_ranges)
        # mask = NArray.new(channel_data.typecode, channel_data.length)
        # mask[0]                   = 1.0
        # mask[1..-1]               = 1000.0
        # mask[high_pass_ranges[0]] = 0
        # # mask[high_pass_ranges[1]] = 0
        # # mask[low_pass_ranges[0]]  = 0
        # # mask[low_pass_ranges[1]]  = 0
        # mask_signal = fft_backward(mask).real.to_a.map { |n| n.magnitude.round(1) }
        # $stdout.puts mask_signal.join(", ")

        # half = f.length / 2
        # tmp = f[1..half].map(&:magnitude).real.to_a.map(&:round)
        # $stdout.puts "#{tmp.length}: #{tmp.join(', ')}"
        # tmp = f[(half + 1)..-1].map(&:magnitude).real.to_a.map(&:round).reverse
        # $stdout.puts "#{tmp.length}: #{tmp.join(', ')}"

        $stdout.puts [data[0], data[0].magnitude].join(" / ")
        $stdout.puts "High: #{high_pass_ranges.inspect}"
        $stdout.puts "High: [#{r_str(high_pass_ranges[0])}, #{r_str(high_pass_ranges[1])}]"
        tmp = data[high_pass_ranges[0]].map(&:magnitude).real.round.to_a
        $stdout.puts "[#{tmp.length}]:   #{tmp.join(', ')}"
        tmp = data[high_pass_ranges[1]].map(&:magnitude).real.round.to_a.reverse
        $stdout.puts "[#{tmp.length}]:   #{tmp.join(', ')}"

        $stdout.puts "Low: #{low_pass_ranges.inspect}"
        $stdout.puts "Low: [#{r_str(low_pass_ranges[0])}, #{r_str(low_pass_ranges[1])}]"
        tmp = data[low_pass_ranges[0]].map(&:magnitude).real.round.to_a
        $stdout.puts "[#{tmp.length}]:   #{tmp.join(', ')}"
        tmp = data[low_pass_ranges[1]].map(&:magnitude).real.round.to_a.reverse
        $stdout.puts "[#{tmp.length}]:   #{tmp.join(', ')}"
        $stdout.puts ">>>>>"
        $stdout.flush
      end
    end
  end
end
