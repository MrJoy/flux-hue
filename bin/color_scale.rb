#!/usr/bin/env ruby
require "rgb"

def to_hex(on)
  col = on.to_rgb.map { |n| ((n / 255.0) * 63.0).round.to_i }
  # puts "#{on.h.round(1)}, #{on.s.round(3)}, #{on.l.round(3)}"
  "0x%02X%02X%02X" % col
end

# on = RGB::Color.from_rgb((0x27 / 63.0) * 255, (0x00 / 63.0) * 255, (0x3F / 63.0) * 255)
# on = RGB::Color.from_rgb((0x02 / 63.0) * 255, (0x00 / 63.0) * 255, (0x04 / 63.0) * 255)

# Jen's palette color:
# on = RGB::Color.from_fractions(49500/65535.0, 1.0, 0.5)
on = RGB::Color.from_fractions(49500/65535.0, 1.0, 0.08)
puts "#{on.h.round(1)}, #{on.s.round(3)}, #{on.l.round(3)}"

results = []
results << to_hex(on)
5.times do
  on.l -= 0.0125
  results << to_hex(on)
end

puts "- #{results.reverse.join("\n- ")}"
