module SparkleMotion
  module Audio
    # Input stream class to read from a file using CoreAudio.
    class FileInputStream < InputStream
      def initialize(file_name, window)
        @name         = File.basename(file_name)
        @input        = CoreAudio::AudioFile.new(file_name, :read)
        @sample_rate  = @input.rate # TODO: Do we want `inner_rate` instead?
        super(window)
      end

      def stop
        super
        @input.close
      end

      def dropped_frames; 0; end
      def finite?; true; end
    end
  end
end
