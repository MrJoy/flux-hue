# TODO: Namespacing/classes/etc!
require "curb"
require "oj"

# TODO: Try to figure out how to set Curl::CURLOPT_TCP_NODELAY => true
# TODO: Disable Curl from sending keepalives by trying HTTP/1.0.
MULTI_OPTIONS = { pipeline:         false,
                  max_connects:     (CONFIG["max_connects"] || 3) }
EASY_OPTIONS = { "timeout" =>         5,
                 "connect_timeout" => 5,
                 "follow_location" => false,
                 "max_redirects" =>   0 } # ,
                 # version:          Curl::HTTP_1_0 }
#   easy.header_str.grep(/keep-alive/)
# Force keepalive off to see if that makes any difference...
# TODO: Use this: `easy.headers["Expect"] = ''` to remove a default header we don't care about!

def hue_server(config); "http://#{config['ip']}"; end
def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
def hue_light_endpoint(config, light_id); "#{hue_base(config)}/lights/#{light_id}/state"; end
def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

def with_transition_time(data, transition)
  data["transitiontime"] = (transition * 10.0).round(0)
  data
end
