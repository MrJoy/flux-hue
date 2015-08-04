#!/usr/bin/env ruby
###############################################################################
# Early Initialization/Helpers
###############################################################################
require "rubygems"
require "bundler/setup"
Bundler.setup

require_relative "./lib/config"
require_relative "./lib/logging"
require_relative "./lib/env"
require_relative "./lib/utility"
require_relative "./lib/http"

###############################################################################
# Main Logic
###############################################################################
VERBOSE = false
# TODO: Also mark accent lights!
in_groups(CONFIG["main_lights"]).map do |(bridge_name, lights)|
  config    = CONFIG["bridges"][bridge_name]
  requests  = lights
              .map do |(idx, lid)|
                LazyRequestConfig.new(config, hue_light_endpoint(config, lid)) do
                  data = {}
                  data["hue"] = config["debug_hue"]
                  data["sat"] = ((200 * (idx / lights.length.to_f)) + 54).round
                  data["bri"] = (254 * (idx / lights.length.to_f)).round
                  with_transition_time(data, 0)
                end
              end

  Curl::Multi.http(requests, MULTI_OPTIONS) do
  end
end
