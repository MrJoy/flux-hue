module SparkleMotion
  module Hue
    # Evil hack to convince Curb to grab simulation-based information as late as
    # possible, to undo the temporal skew that comes from updating the simulation
    # then spending a bunch of time feeding updates to lights.
    class LazyRequestConfig
      GLOBAL_HISTORY = []

      attr_reader :url, :http_method, :bridge
      def initialize(logger, bridge, http_method, url, results = nil, debug: nil, &callback)
        @logger       = logger
        @bridge       = bridge
        @http_method  = http_method
        @url          = url
        @results      = results
        @callback     = callback
        @fixed        = create_fixed
        @debug        = debug
      end

      def each(&block)
        SparkleMotion::Hue::HTTP::EASY_OPTIONS.each do |kv|
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

        @logger.error { "Request for unknown field: `#{field}`!  Has Curb changed internally?" }
        nil
      end

    protected

      def error(msg); "#{@bridge['name']}; #{@url}: #{msg}"; end
      def overloaded(easy); error("Bridge overloaded: #{easy.body}"); end
      def unknown_error(easy); error("Unknown error: #{easy.response_code}, #{easy.body}"); end
      def hard_timeout(_easy); error("Request timed out."); end
      def soft_timeout(easy); error("Failed updating light: #{easy.body}"); end

      def create_fixed
        # TODO: Maybe skip per-event callbacks and go for single handler?
        { url:         url,
          method:      http_method,
          headers:     nil,
          on_failure:  proc { |easy, _| failure!(easy) },
          on_success:  proc { |easy| success!(easy) },
          on_progress: nil,
          on_debug:    nil,
          on_body:     nil,
          on_header:   nil }
      end

      def journal(stage, easy)
        return unless @debug
        body = easy.respond_to?(:body_str) ? easy.body : easy[:body]
        GLOBAL_HISTORY << "#{Time.now.to_f},#{stage},#{@url},#{body}"
      end

      def failure!(easy)
        journal("END", easy)
        case easy.response_code
        when 404  # Hit Bridge hardware limit.
          @results.failure!(overloaded(easy)) if @results
        when 0    # Hit timeout.
          @results.hard_timeout!(hard_timeout(easy)) if @results
        else
          @results.failure!(unknown_error(easy))
        end
      end

      def success!(easy)
        journal("END", easy)
        if easy.body =~ /error/
          # TODO: Check the error type field to be sure, and handle accordingly.

          # Hit bridge rate limit / possibly ZigBee
          # limit?.
          @results.soft_timeout!(soft_timeout(easy)) if @results
        else
          @results.success! if @results
        end
      end
    end
  end
end
