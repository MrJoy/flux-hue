#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
SparkleMotion.init!("discover")
SparkleMotion.use_hue!(discovery: true)

def ip_atob(ip)
  ip.split(/\./).map(&:to_i).pack("C4")
end

results = SparkleMotion::Hue::SSDP.new.scan
puts results.values.sort { |a, b| ip_atob(a) <=> ip_atob(b) }.join("\n")
