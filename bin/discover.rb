#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flux_hue"
FluxHue.init!("off")
FluxHue.use_hue!(discovery: true)

def ip_atob(ip)
  ip.split(/\./).map(&:to_i).pack("C4")
end

results = FluxHue::Hue::SSDP.new.scan
puts results.values.sort { |a, b| ip_atob(a) <=> ip_atob(b) }.join("\n")
