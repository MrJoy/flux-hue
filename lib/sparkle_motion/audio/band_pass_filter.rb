module SparkleMotion
  module Audio
    # Implements a simple band-pass filter.
    class BandPassFilter
      attr_reader :frequency_range, :bin_start, :bin_end, :bin_count
      def initialize(freq_range, sample_rate, window, enable_low, enable_high, &callback)
        @sample_rate          = sample_rate
        @window               = window
        @half                 = window / 2
        @callback             = callback
        @enable_low           = enable_low
        @enable_high          = enable_high
        self.frequency_range  = freq_range
      end

      def frequency_range=(val)
        return if @frequency_range == val
        @frequency_range = val.dup
        compute_bins!
      end

      def apply!(fft)
        # Example code demonstrating a pitch-shift, from here:
        # https://github.com/nagachika/ruby-coreaudio/blob/master/examples/fft_shift_pitch.rb
        #   shift = 12
        #   f[ch, (shift + 1)...half] = f[ch, 1...(half - shift)]
        #   f[ch, 1..shift] = 0
        #   f[ch, (half + 1)...(w.shape[1] - shift)] = f[ch, (half + shift + 1)..-1]
        #   f[ch, -shift..-1] = 0

        # Low-pass portion of filter:
        apply_low_pass!(fft)

        # High-pass portion of filter:
        apply_high_pass!(fft)
      end

    protected

      def apply_low_pass!(fft)
        return unless @enable_low

        # $stdout.puts ">>> #{((bin_end + 1)...@half).inspect}"
        # $stdout.puts "    #{((@half + 1)...-(bin_end + 1)).inspect}"
        # $stdout.puts "    #{fft.size.inspect}"
        # $stdout.flush
        fft[(bin_end + 1)...@half]        = 0
        fft[(@half + 1)...-(bin_end + 1)] = 0
      end

      def apply_high_pass!(fft)
        return unless @enable_high

        # $stdout.puts ">>> 1..#{bin_start - 1}"
        # $stdout.puts "    #{-(bin_start - 1)}..-1"
        # $stdout.flush
        fft[1..(bin_start - 1)]   = 0
        fft[-(bin_start - 1)..-1] = 0
      end

      # def bin_freq(idx); ((idx - 1) * @sample_rate) / @window; end
      def freq_bin(hz); (((hz * @window) / @sample_rate).round / 2) + 1; end

      def compute_bins!
        @bin_end    = min(freq_bin(@frequency_range.last), @half)
        @bin_start  = min(freq_bin(@frequency_range.first), bin_end)
        @bin_count  = bin_end - bin_start + 1
        @callback.call(bin_start, bin_end, @bin_count) if @callback
      end

      def min(a, b); a < b ? a : b; end
    end
  end
end
