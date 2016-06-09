module SparkleMotion
  module Hue
    # Evil hack to convince Curb to grab simulation-based information as late as
    # possible, to undo the temporal skew that comes from updating the simulation
    # then spending a bunch of time feeding updates to lights.
    class LazyRequestConfig
      GLOBAL_HISTORY = []

      # TODO: Look into Curl::Easy method:
      # TODO: app_connect_time, connect_time, connect_timeout, dns_cache_timeout, file_time,
      # TODO: low_speed_limit, low_speed_time, name_lookup_time, pre_transfer_time,
      # TODO: redirect_time, resolve_mode, start_transfer_time, timeout, total_time, verbose
      # puts "  total_time:           %.5f" % _easy.total_time                  # total time in seconds for the previous transfer, including name resolving, TCP connect etc.
      # puts "    start_transfer_time:  %.5f" % _easy.start_transfer_time       # from the start until the first byte is just about to be transferred. This includes the pre_transfer_time and also the time the server needs to calculate the result.
      # puts "      pre_transfer_time:    %.5f" % _easy.pre_transfer_time       # from the start until the file transfer is just about to begin. This includes all pre-transfer commands and negotiations that are specific to the particular protocol(s) involved.
      # puts "        connect_time:         %.5f" % _easy.connect_time          # from the start until the connect to the remote host (or proxy) was completed.
      # puts "          name_lookup_time:     %.5f" % _easy.name_lookup_time    # from the start until the name resolving was completed
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

      def body_str; ""; end
      def body; ""; end
      def dummy!; success!(self); end

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
        if stage == "BEGIN"
          @started_at = Time.now.to_f
          @body = body
          tmp = @callback.call
          @target_bri = tmp["bri"]
          @pieces = @url.split('/')
        else
          GLOBAL_HISTORY << "#{@started_at},#{Time.now.to_f},#{@pieces[2]},#{@pieces[6]},#{@target_bri}"
        end
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
