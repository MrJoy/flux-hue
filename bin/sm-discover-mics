#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
Bundler.setup
require "coreaudio"

CoreAudio.devices.each do |device|
  puts "#{device.devid}: #{device.name} (#{device.actual_rate}Hz)"
end
