module SparkleMotion
  module Audio
    # Input stream class to read from an input device using CoreAudio.
    class DeviceInputStream < InputStream
      def initialize(device_name, window)
        @input_device = CoreAudio.devices.find { |dev| dev.name =~ /#{device_name}/ }
        fail "No such device ID!" unless @input_device

        @name         = @input_device.name
        @input        = @input_device.input_buffer(window)
        @sample_rate  = @input_device.actual_rate
        super(window)
      end

      def start
        @input.start
        super
      end

      def stop
        super
        @input.stop
      end

      def finite?; false; end
      def dropped_frames; @input.dropped_frame; end
    end
  end
end
