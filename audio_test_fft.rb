#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
Bundler.setup
require "thread"
require "coreaudio"
require "fftw3"

Thread.abort_on_exception = true

WINDOW      = 1024
device      = CoreAudio.default_input_device
inbuf       = device.input_buffer(WINDOW)
SAMPLE_RATE = device.actual_rate

puts "Sampling at #{SAMPLE_RATE}hz from #{device.name}..."
# def bin_freq(idx); (idx * SAMPLE_RATE) / WINDOW; end
def freq_bin(hz); ((hz * WINDOW) / SAMPLE_RATE).round; end

# Only care about frequencies from 300hz to 3khz...
# Do we need to go around the mid-point a la the pitch-shifting code did?
#     half = w.shape[1] / 2
#     f = FFTW3.fft(w, 1)
#     shift = 12
#     f.shape[0].times do |ch|
#       f[ch, (shift+1)...half] = f[ch, 1...(half-shift)]
#       f[ch, 1..shift] = 0
#       f[ch, (half+1)...(w.shape[1]-shift)] = f[ch, (half+shift+1)..-1]
#       f[ch, -shift..-1] = 0

bin_start = freq_bin(300)
bin_end   = freq_bin(3_000)

# TODO: Look into this to allow routing AudioHijack output into processor? http://www.ambrosiasw.com/utilities/wta/
# http://www.abstractnew.com/2014/04/the-fast-fourier-transform-fft-without.html

queue = Queue.new
pitch_shift_th = Thread.start do
  while w = queue.pop
    f = FFTW3.fft(w, 1)

    # Because of NArray, the `map` eaves magnitude of each `Complex` in the
    # real component of a new Complex. >.<
    amplitudes    = f[0, bin_start..bin_end].map(&:magnitude)
    avg_amplitude = amplitudes.sum.real / WINDOW
    puts avg_amplitude.round(1)
  end
end

th = Thread.start do
  loop do
    queue.push(inbuf.read(WINDOW))
  end
end

inbuf.start
$stdout.puts "Press enter to terminate..."
$stdout.flush
$stdin.gets
queue.push(nil)
inbuf.stop
th.kill.join
pitch_shift_th.kill.join

puts "#{inbuf.dropped_frame} frame dropped at input buffer."
