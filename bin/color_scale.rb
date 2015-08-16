#!/usr/bin/env ruby
require "rgb"

def show_color(on)
  col = on.to_rgb.map { |n| ((n / 255.0) * 63.0).round.to_i }
  # puts "#{on.h.round(1)}, #{on.s.round(3)}, #{on.l.round(3)}"
  puts "  0x%02X%02X%02X" % col
end

# on  = RGB::Color.from_rgb((0x27 / 63.0) * 255, (0x00 / 63.0) * 255, (0x3F / 63.0) * 255)
on = RGB::Color.from_rgb((0x02 / 63.0) * 255, (0x00 / 63.0) * 255, (0x04 / 63.0) * 255)
puts "#{on.h.round(1)}, #{on.s.round(3)}, #{on.l.round(3)}"
show_color(on)

5.times do
  on.l -= 0.004
  show_color(on)
end
