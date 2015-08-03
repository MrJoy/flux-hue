require "curb"
require "oj"

# TODO: Try to figure out how to set Curl::CURLOPT_TCP_NODELAY => true
# TODO: Disable Curl from sending keepalives by trying HTTP/1.0.
MULTI_OPTIONS   = { pipeline:         false,
                    max_connects:     (env_int("MAX_CONNECTS") || 3) }
EASY_OPTIONS    = { timeout:          5,
                    connect_timeout:  5,
                    follow_location:  false,
                    max_redirects:    0 }

def hue_server(config); "http://#{config['ip']}"; end
def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
def hue_light_endpoint(config, light_id); "#{hue_base(config)}/lights/#{light_id}/state"; end
def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

def with_transition_time(data, transition)
  data["transitiontime"] = (transition * 10.0).round(0)
end

# Evil hack to convince Curb to grab simulation-based information as late as
# possible, to undo the temporal skew that comes from updating the simulation
# then spending a bunch of time feeding updates to lights.
class LazyRequestConfig
  # TODO: Transition should be updated late as well...
  def initialize(config, url, results = nil, &callback)
    @config     = config
    @url        = url
    @results    = results
    @callback   = callback
  end

  def each(&block)
    EASY_OPTIONS.each do |kv|
      block.call(kv)
    end
  end

  def delete(field)
    return fixed[field] if fixed.key?(field)
    return Oj.dump(@callback.call) if field == :put_data

    wtf!(field)
    nil
  end

protected

  def fixed
    @fixed ||= {  url:          @url,
                  method:       :put,
                  headers:      nil,
                  on_failure:   proc { |easy, _| failure!(easy) },
                  on_success:   proc { |easy| success!(easy) },
                  on_progress:  nil,
                  on_debug:     nil,
                  on_body:      nil,
                  on_header:    nil }
  end

  def wtf!(field)
    error @config, "Request for unknown field: `#{field}`!  Has Curb been updated"\
      " in a breaking way?"
  end

  def failure!(easy)
    case easy.response_code
    when 404
      # Hit Bridge hardware limit.
      @results.failed! if @results
      printf "*"
    when 0
      # Hit timeout.
      @results.hard_timeout! if @results
      printf "-"
    else
      error bridge_name, "WAT: #{easy.response_code}"
    end
  end

  def success!(easy)
    if easy.body =~ /error/
      # TODO: Check the error type field to be sure, and handle accordingly.

      # Hit bridge rate limit / possibly ZigBee
      # limit?.
      @results.soft_timeout! if @results
      printf "~"
      # TODO: Colorized output for all feedback types, or running counters, or
      # TODO: something...
      # printf ("%02X" % @index)
    else
      @results.success! if @results
      printf "." if VERBOSE
    end
  end
end
