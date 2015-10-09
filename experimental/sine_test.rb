require "rubygems"
require "bundler/setup"
Bundler.setup
require "coreaudio"

WINDOW = 1024
VOLUME = 0.1 * 0x7FFF

dev = CoreAudio.default_output_device
buf = dev.output_buffer(WINDOW)

phase = Math::PI * 2.0 * 440.0 / dev.nominal_rate
th = Thread.start do
  i = 0
  wav = NArray.sint(WINDOW)
  loop do
    WINDOW.times { |j| wav[j] = (VOLUME * Math.sin(phase * (i + j))).round }
    i += WINDOW
    buf << wav
  end
end

buf.start
sleep 2
th.kill.join
buf.stop

puts "#{buf.dropped_frame} frames dropped."
