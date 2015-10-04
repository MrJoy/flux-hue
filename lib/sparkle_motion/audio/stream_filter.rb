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
          data = normalize(fft_forward(frame[channel, 0..-1]))

          @filter.apply!(data)

          snapshot << data
        end

        @handler.call(snapshot, drop_count) if @handler

        send(snapshot)
      end
    end
  end
end
