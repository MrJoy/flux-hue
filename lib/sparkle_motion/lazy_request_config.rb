module SparkleMotion
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
      # rubocop:disable Style/RescueModifier
      GLOBAL_HISTORY << "#{Time.now.to_f},#{stage},#{@url},#{easy.body_str rescue nil}"
      # rubocop:enable Style/RescueModifier
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
end
