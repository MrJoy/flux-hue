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

def hue_server(config); "http://#{config['ip']}"; end
def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
def hue_light_endpoint(config, light_id); "#{hue_base(config)}/lights/#{light_id}/state"; end
def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

def with_transition_time(data, transition)
  data["transitiontime"] = (transition * 10.0).round(0)
  data
end

# Evil hack to convince Curb to grab simulation-based information as late as
# possible, to undo the temporal skew that comes from updating the simulation
# then spending a bunch of time feeding updates to lights.
class LazyRequestConfig
  GLOBAL_HISTORY = []
  # TODO: Transition should be updated late as well...
  def initialize(logger, config, url, results = nil, debug: nil, &callback)
    @logger     = logger
    @config     = config
    @url        = url
    @results    = results
    @callback   = callback
    @fixed      = create_fixed(url)
    @debug      = debug
  end

  def each(&block)
    EASY_OPTIONS.each do |kv|
      block.call(kv)
    end
  end

  def delete(field)
    return @fixed[field] if @fixed.key?(field)
    if field == :put_data
      tmp = Oj.dump(@callback.call)
      journal("BEGIN", body: tmp)
      return tmp
    end

    error "Request for unknown field: `#{field}`!  Has Curb been updated in a breaking way?"
    nil
  end

protected

  def error(&msg); @logger.error { "#{@config['name']}; #{@url}: #{msg.call}" }; end
  def debug(&msg); @logger.debug { "#{@config['name']}; #{@url}: #{msg.call}" }; end

  def create_fixed(url)
    {  url:          url,
       method:       :put,
       headers:      nil,
       # TODO: Maybe skip per-event callbacks and go for single
       # TODO: callback?
       on_failure:   proc { |easy, _| failure!(easy) },
       on_success:   proc { |easy| success!(easy) },
       on_progress:  nil,
       on_debug:     nil,
       on_body:      nil,
       on_header:    nil }
  end

  def journal(stage, easy)
    return unless @debug
    GLOBAL_HISTORY << "#{Time.now.to_f},#{stage},#{@url},#{easy.body_str rescue nil}"
  end

  def failure!(easy)
    journal("END", easy)
    case easy.response_code
    when 404
      # Hit Bridge hardware limit.
      @results.failed! if @results
      error { "Failed updating light, bridge overloaded: #{easy.body}" }
    when 0
      # Hit timeout.
      @results.hard_timeout! if @results
      error { "Failed updating light, request timed out." }
    else
      error { "Failed updating light, unknown error: #{easy.response_code}, #{easy.body}" }
    end
  end

  def success!(easy)
    journal("END", easy)
    if easy.body =~ /error/
      # TODO: Check the error type field to be sure, and handle accordingly.

      # Hit bridge rate limit / possibly ZigBee
      # limit?.
      @results.soft_timeout! if @results
      error { "Failed updating light: #{easy.body}" }
      # TODO: Colorized output for all feedback types, or running counters, or
      # TODO: something...
      # printf ("%02X" % @index)
    else
      @results.success! if @results
      # debug { "Updated light." }
    end
  end
end
