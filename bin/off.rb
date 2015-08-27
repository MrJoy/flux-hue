#!/usr/bin/env ruby

###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
SparkleMotion.init!("off")
SparkleMotion.use_hue!(api: true)

###############################################################################
# Helper Functions
###############################################################################
def make_req_struct(url, data)
  { method:   :put,
    url:      url,
    put_data: Oj.dump(data) }.merge(EASY_OPTIONS)
end

def hue_init(config)
  make_req_struct(hue_group_endpoint(config, 0), "on" => false)
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
    SparkleMotion.logger.error { "Failed to initialize light: #{easy.url}" }
    add(easy)
  end
end
