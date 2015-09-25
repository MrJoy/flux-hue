#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
Bundler.setup
require "thread"
require "coreaudio"
require "fftw3"

Thread.abort_on_exception = true

WINDOW = 1024

inbuf = CoreAudio.default_input_device.input_buffer(WINDOW)

queue = Queue.new
pitch_shift_th = Thread.start do
  while w = queue.pop
    f = FFTW3.fft(w, 1)
    puts (f[0, 1..(w.shape[1] - 1)].map(&:abs).sum.real / WINDOW).round(1)
  end
end

th = Thread.start do
  loop do
    wav = inbuf.read(WINDOW)
    queue.push(wav)
  end
end

inbuf.start
$stdout.print "loopback..."
$stdout.flush
$stdin.gets
queue.push(nil)
inbuf.stop
$stdout.puts "done."
th.kill.join
pitch_shift_th.kill.join

puts "#{inbuf.dropped_frame} frame dropped at input buffer."
