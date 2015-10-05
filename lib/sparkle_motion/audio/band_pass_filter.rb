module SparkleMotion
  module Audio
    # Implements a simple band-pass filter.
    class BandPassFilter
      # http://masa16.github.io/narray/SPEC.en.txt
      #
      # https://en.wikipedia.org/wiki/Gibbs_phenomenon
      # https://en.wikipedia.org/wiki/Sigma_approximation
      # https://groups.google.com/forum/#!search/%22Frequency$20domain$20filtering$20%28rectangular$20window$20question%29%22/comp.dsp/__gS8i1kOfQ/zDbNIvdqN6EJ
      #   '... the "overlap-add" or "overlap-save" methods.'
      # http://stackoverflow.com/questions/4364823/how-do-i-obtain-the-frequencies-of-each-value-in-a-fft
      #
      # Any signal "between the bins" gets smeared out among all the other
      # bins, not just the closest bin.  Try it: fft a single sine wave
      # with a frequency that is between the fft bins.  Also note the phases
      # of the resulting fft on opposite sides of your center frequency.
      #
      # A true "Brick wall" is infinitely long. Without a window, even that
      # rings. (OK: all bets are off when passing to infinity. Infinity - 1
      # rings. :-)
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

      def nominal_bin_start; @bin_start + 1; end
      def nominal_bin_end; @bin_end - 1; end

      def bin_start; @enable_high ? @bin_start : 1; end
      def bin_end; @enable_low ? @bin_end : (@half - 1); end

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

      def low_pass_ranges; @low_pass_ranges; end
      def high_pass_ranges; @high_pass_ranges; end

      def apply_low_pass!(fft)
        return unless @enable_low

        clear(fft, low_pass_ranges[0])
        clear(fft, low_pass_ranges[1])
      end

      def apply_high_pass!(fft)
        return unless @enable_high

        clear(fft, high_pass_ranges[0])
        clear(fft, high_pass_ranges[1])
      end

      def clear(data, range); data[range] = 0; end

      # def bin_freq(idx); (idx.to_f / @sample_rate / @half.to_f); end
      def freq_bin(hz); (hz / (@sample_rate.to_f / @window.to_f)).round + 1; end

      def compute_bins!
        old_end     = @bin_end
        old_start   = @bin_start
        @bin_end    = min(freq_bin(@frequency_range.last), @half - 1)
        @bin_start  = min(freq_bin(@frequency_range.first), bin_end)
        @bin_count  = (bin_end - 1) - (bin_start + 1) + 1
        changed     = old_end != @bin_end || old_start != @bin_start
        return unless changed || @low_pass_ranges.nil? || @high_pass_ranges.nil?
        @low_pass_ranges = @high_pass_ranges = nil

        @low_pass_ranges  = [@bin_end...@half, (@half + 1)...-@bin_end] if @enable_low
        @high_pass_ranges = [1..@bin_start, -@bin_start..-1] if @enable_high

        @callback.call(bin_start + 1, bin_end - 1, @bin_count) if @callback
      end

      def min(a, b); a < b ? a : b; end
    end
  end
end
