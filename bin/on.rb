#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flux_hue"
FluxHue.init!
FluxHue.use_hue!

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
INIT_HUE      = env_int("INIT_HUE", true) || 49_500
INIT_SAT      = env_int("INIT_SAT", true) || 254
INIT_BRI      = env_int("INIT_BRI", true) || 127

###############################################################################
# Helper Functions
###############################################################################
def make_req_struct(url, data)
  { method:   :put,
    url:      url,
    put_data: Oj.dump(data) }.merge(EASY_OPTIONS)
end

def hue_init(config)
  make_req_struct(hue_group_endpoint(config, 0), "on"  => true,
                                                 "bri" => INIT_BRI,
                                                 "sat" => INIT_SAT,
                                                 "hue" => INIT_HUE)
end

###############################################################################
# Main
###############################################################################
# TODO: Hoist this into a separate script.
# debug "Initializing lights..."
init_reqs = CONFIG["bridges"]
            .values
            .map { |config| hue_init(config) }
Curl::Multi.http(init_reqs, MULTI_OPTIONS) do |easy|
  if easy.response_code != 200
    FluxHue.logger.error { "Failed to initialize light: #{easy.url}" }
    add(easy)
  end
end
