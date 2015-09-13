#!/usr/bin/env ruby
###############################################################################
# Early Initialization/Helpers
###############################################################################
lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sparkle_motion"
SparkleMotion.init!("mark_lights")
SparkleMotion.use_hue!(api: true)
LOGGER = SparkleMotion.logger

###############################################################################
# Main Logic
###############################################################################
# TODO: Also mark accent lights, dance lights, etc.
#
# TODO: Use Novation Launchpad to be able to toggle lights.
def light_state(hue, index, num_lights)
  target      = (254 * (index / num_lights.to_f)).round
  data        = { "on" => true,
                  "hue" => hue,
                  "sat" => target,
                  "bri" => target }
  with_transition_time(data, 0)
end

# TODO: Speed this up by setting on/hue via group message per bridge...
%w(main_lights dance_lights accent_lights).each do |group_name|
  config      = SparkleMotion::LightConfig.new(config: CONFIG, group: group_name)
  url_req_map = {}
  config.bridges.each do |bridge_name, bridge|
    light_ids   = config.lights[bridge_name].map(&:last)
    hue         = bridge["debug_hue"]
    index       = 0
    num_lights  = light_ids.length
    requests    = light_ids
                  .map do |lid|
                    url               = hue_light_endpoint(bridge, lid)
                    color             = light_state(hue, index, num_lights)
                    index            += 1
                    url_req_map[url]  = SparkleMotion::LazyRequestConfig.new(LOGGER, bridge, url) do
                      color
                    end
                  end

    next unless requests.length > 0
    while requests.length > 0
      retry_queue = []
      Curl::Multi.http(requests, MULTI_OPTIONS) do |easy|
        if easy.response_code != 200 ||
           easy.body =~ /error/
          url = easy.url
          LOGGER.error { "#{url} => #{easy.response_code} / #{easy.body}" }
          retry_queue << url
        end
      end
      requests = retry_queue.map { |url| url_req_map[url] }
    end
  end
end
