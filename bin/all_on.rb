#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
require "rubygems"
require "bundler/setup"
Bundler.setup
require "yaml"
require "curb"
require "oj"

require_relative "./lib/env"
require_relative "./lib/logging"

###############################################################################
# Timing Configuration
#
# Play with this to see how error rates are affected.
###############################################################################

MULTI_OPTIONS   = { pipeline:         false,
                    max_connects:     (env_int("MAX_CONNECTS") || 3) }
EASY_OPTIONS    = { timeout:          5,
                    connect_timeout:  5,
                    follow_location:  false,
                    max_redirects:    0 }

###############################################################################
# Effect
#
# Tweak this to change the visual effect.
###############################################################################
INIT_HUE      = env_int("INIT_HUE", true) || 49_500
INIT_SAT      = env_int("INIT_SAT", true) || 254
INIT_BRI      = env_int("INIT_BRI", true) || 127

###############################################################################
# Bring together defaults and env vars, initialize things, etc...
###############################################################################
CONFIG        = YAML.load(File.read("config.yml"))

###############################################################################
# Helper Functions
###############################################################################
def hue_server(config); "http://#{config['ip']}"; end
def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

def make_req_struct(url, data)
  tmp = { method:   :put,
          url:      url,
          put_data: Oj.dump(data) }
  tmp.merge(EASY_OPTIONS)
end

def hue_init(config)
  url = hue_group_endpoint(config, 0)

  make_req_struct(url, "on"  => true,
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
    error "Failed to initialize light (will try again): #{easy.url}"
    add(easy)
  end
end
