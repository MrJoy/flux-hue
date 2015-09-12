#!/usr/bin/env ruby
###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
SparkleMotion.init!("mark_lights")
SparkleMotion.use_hue!(api: true)

###############################################################################
# Main Logic
###############################################################################
# TODO: Also mark accent lights, dance lights, etc.
#
# TODO: Use Novation Launchpad to be able to toggle lights.
in_groups(CONFIG["main_lights"]).map do |(bridge_name, lights)|
  config    = CONFIG["bridges"][bridge_name]
  lights    = lights.first.map(&:last)
  counter   = 0
  logger    = SparkleMotion.logger
  requests  = lights
              .map do |lid|
                url = hue_light_endpoint(config, lid)
                SparkleMotion::LazyRequestConfig.new(logger, config, url) do
                  counter    += 1
                  target      = (254 * (counter / lights.length.to_f)).round
                  data        = {}
                  data["on"]  = true
                  data["hue"] = config["debug_hue"]
                  # data["sat"] = ((200 * (idx / lights.length.to_f)) + 54).round
                  data["sat"] = target
                  data["bri"] = target
                  with_transition_time(data, 0)
                end
              end

  Curl::Multi.http(requests, MULTI_OPTIONS) do
  end
end
