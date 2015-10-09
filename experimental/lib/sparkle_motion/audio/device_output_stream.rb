module SparkleMotion
  module Audio
    # Wrapper around the CoreAudio default output device.  Requiring you to use that one because
    # I don't see a convenient way to set the output rate for any other device, and don't have the
    # time or compelling need to track that detail down.
    class DeviceOutputStream < OutputStream
      def initialize(rate, window)
        configure_output_device!(rate)

        @device       = CoreAudio.default_output_device
        @name         = @device.name
        @output       = @device.output_buffer(window)
        @sample_rate  = @device.actual_rate

        super(rate, window)
      end

      def start; @output.start; end
      def stop; @output.stop; end
      def write(val); @output << val; end

    protected

      def configure_output_device!(rate)
        available_rates = CoreAudio.default_output_device.available_sample_rate.flatten.uniq
        rate = rate.to_f
        unless rate && available_rates.member?(rate)
          fail "Can't set default output device to #{rate}hz!"
        end

        CoreAudio.default_output_device(nominal_rate: rate)
      end
    end
  end
end
