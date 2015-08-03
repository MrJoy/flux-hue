def hue_server(config); "http://#{config['ip']}"; end
def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
def hue_light_endpoint(config, light_id); "#{hue_base(config)}/lights/#{light_id}/state"; end
def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

def with_transition_time(data, transition)
  data["transitiontime"] = (transition * 10.0).round(0)
end
