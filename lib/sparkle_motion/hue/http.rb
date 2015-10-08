require "oj"
require "curb"
require "socket"
require "net/http"

module SparkleMotion
  module Hue
    # Helpers for interacting with the Philips Hue Bridge.
    module HTTP
      # TODO: Try to figure out how to set Curl::CURLOPT_TCP_NODELAY => true
      # TODO: Disable Curl from sending keepalives by trying HTTP/1.0.
      MULTI_OPTIONS = { pipeline:     false,
                        max_connects: (::CONFIG["max_connects"] || 3) }
      EASY_OPTIONS = { "timeout" =>         5,
                       "connect_timeout" => 5,
                       "follow_location" => false,
                       "max_redirects" =>   0 } # ,
                       # version:          Curl::HTTP_1_0 }
      #   easy.header_str.grep(/keep-alive/)
      # Force keepalive off to see if that makes any difference...
      # TODO: Use this: `easy.headers["Expect"] = ''` to remove default header we don't care about!
      def hue_server(config); "http://#{config['ip']}"; end
      def hue_base(config); "#{hue_server(config)}/api/#{config['username']}"; end
      def hue_light_endpoint(config, light_id); "#{hue_base(config)}/lights/#{light_id}/state"; end
      def hue_group_endpoint(config, group); "#{hue_base(config)}/groups/#{group}/action"; end

      def endpoint_url(bridge); "http://#{bridge['ip']}"; end
      def bridge_query_url(bridge); "#{endpoint_url(bridge)}/api/#{bridge['username']}"; end
      def light_query_url(bridge, light_id); "#{bridge_query_url(bridge)}/lights/#{light_id}"; end
      def light_update_url(bridge, light_id); "#{light_query_url(bridge, light_id)}/state"; end
      def group_query_url(bridge, group_id); "#{bridge_query_url(bridge)}/groups/#{group_id}"; end
      def group_update_url(bridge, group_id); "#{group_query_url(bridge, group_id)}/action"; end

      # Class to encapsulate a request to the Hue Bridge, using `TCPSocket` for low-overhead
      # communication.
      class TCPSocketRequest
        attr_reader :bridge, :action, :light_id, :group_id, :http_method, :uri, :payload, :callback

        def initialize(bridge, action, light_id: nil, group_id: nil, payload: nil, &callback)
          @bridge             = bridge
          @action             = action
          @payload            = payload
          @target, @target_id = target_from(action, light_id, group_id)
          @http_method, @uri  = http_params_from(action, @target, @target_id)
          @callback           = callback
          @stopwatch          = StopWatch.new(8) # Num steps we expect to take in `perform`.
        end

        def perform
          # Hue Bridge generally gives us:
          #   * 1x Response status line
          #   * 3x cache-related header
          #   * 1x Connection close indicator
          #   * 5x access control header
          #   * 1x Content type
          #   * 1x Body separator (blank)
          #   * 1x Response body, as a one-liner
          # ... so we allocate 14 entries right off the bat to avoid reallocating any under-the-hood
          # blocks of memory, etc.
          @stopwatch.begin!
          response = Array.new(14)
          @stopwatch.record!(:allocated)

          socket = TCPSocket.new(bridge["ip"], bridge["port"] || 80)
          @stopwatch.record!(:connect)

          message = request_body(http_method, uri, payload, @callback)
          @stopwatch.record!(:request_synthesized)

          socket.write(message)
          socket.flush
          @stopwatch.record!(:request_sent)

          read_response(socket, response)
          @stopwatch.record!(:response_received)

          socket.close
          @stopwatch.record!(:connection_closed)

          result = parse_response(response)
          @stopwatch.record!(:response_parsed)

          result
        end

      protected

        def parse_response(response)
          status  = nil
          body    = []
          state   = :find_status
          response.each do |line|
            case state
            when :find_status
              matches = STATUS_EXP.match(line)
              # TODO: If we *don't* see a match, something went awry and we should bomb out.
              status  = matches[:code].to_i if matches && matches[:code]
              state   = :find_body
            when :find_body
              state = :capture_body if line == "\r\n"
            when :capture_body
              body << line
            end
          end
          [error?(status, body), status, body]
        end

        def read_response(socket, response)
          idx = 0
          loop do
            tmp = socket.gets
            break unless tmp
            @stopwatch.record!(:first_byte) if idx == 0

            response[idx] = tmp
            idx += 1
          end
        end

        def request_body(http_method, uri, payload, callback)
          command = "#{http_method} #{uri} HTTP/1.0"
          if http_method == "GET" || http_method == "DELETE"
            message = "#{command}\n\n"
          else
            body    = Oj.dump(payload ? payload : callback.call)
            len     = body.length
            message = "#{command}\nContent-Length: #{len}\n\n#{body}\n\n"
          end
          message
        end

        def error?(status, body); (status != 200) || (!!body.find { |line| line =~ /error/ }); end

        def http_params_from(action, target, target_id)
          http_method = case action
                        when :query              then "GET"
                        when :configure, :update then "PUT"
                        when :delete             then "DELETE"
                        when :create             then "POST"
                        else
                          fail "Unknown action '#{action}'!"
                        end

          uri = case action
                when :update                     then update_uri(target, target_id)
                when :query, :configure, :delete then query_uri(target, target_id)
                when :create                     then query_uri(target, nil)
                end

          [http_method, uri]
        end

        def target_from(action, light_id, group_id)
          case
          when group_id && light_id then fail "Must specify 0 or 1 of [light_id, group_id]!"
          when group_id             then [:group, group_id]
          when light_id             then [:light, light_id]
          when action == :create    then [:group]
          else                           [:bridge]
          end
        end

        STATUS_EXP      = %r{\AHTTP/(\d+\.\d+) (?<code>\d+)}
        QUERY_SCOPE     = { light: "lights", group: "groups" }
        ACTION_ENDPOINT = { light: "state", group: "action" }

        def query_uri(target, target_id)
          base = "/api/#{bridge['username']}"
          scope = QUERY_SCOPE[target]
          scope ? (target_id ? "#{base}/#{scope}/#{target_id}" : "#{base}/#{scope}") : base
        end

        def update_uri(target, target_id)
          fail "Can't update a bridge!" if target == :bridge
          "#{query_uri(target, target_id)}/#{ACTION_ENDPOINT[target]}"
        end
      end

      # Class to enccapsulate a request to the Hue Bridge, using `Net::HTTP` for better
      # compatibility.
      class NetHTTPRequest
        attr_reader :bridge, :action, :light_id, :group_id, :http_method, :uri, :payload, :callback

        def initialize(bridge, action, light_id: nil, group_id: nil, payload: nil, &callback)
          @bridge             = bridge
          @action             = action
          @payload            = payload
          @target, @target_id = target_from(action, light_id, group_id)
          @http_method, @uri  = http_params_from(action, @target, @target_id)
          @callback           = callback
          @stopwatch          = StopWatch.new(2) # Num steps we expect to take in `perform`.
        end

        def perform
          # Hue Bridge generally gives us:
          #   * 1x Response status line
          #   * 3x cache-related header
          #   * 1x Connection close indicator
          #   * 5x access control header
          #   * 1x Content type
          #   * 1x Body separator (blank)
          #   * 1x Response body, as a one-liner
          # ... so we allocate 14 entries right off the bat to avoid reallocating any under-the-hood
          # blocks of memory, etc.
          @stopwatch.begin!
          response = Array.new(14)
          @stopwatch.record!(:allocated)

          url = URI("http://#{bridge['ip']}:#{bridge['port'] || 80}#{uri}")
          case http_method
          when "GET"    then response = Net::HTTP.get_response(url)
          when "DELETE" then response = Net::HTTP.delete(url)
          when "PUT", "POST"
            if http_method == "PUT"
              req = Net::HTTP::Put.new(url)
            else
              req = Net::HTTP::Post.new(url)
            end
            req.content_type = "application/json"
            response = Net::HTTP.start(url.hostname, url.port) do |http|
              req.body = Oj.dump(payload || callback.call)
              req.content_length = req.body.length
              http.request(req)
            end
          end
          @stopwatch.record!(:request_sent)

          result = parse_response(response)
          @stopwatch.record!(:response_parsed)

          result
        end

      protected

        def parse_response(response)
          error = true
          error = false if response.code.to_i == 200 && response.body !~ /error/
          [error, response.code, response.body.split(/\r?\n/)]
        end

        def http_params_from(action, target, target_id)
          http_method = HTTP_METHODS[action]

          uri = case action
                when :update                     then update_uri(target, target_id)
                when :query, :configure, :delete then query_uri(target, target_id)
                when :create                     then query_uri(target, nil)
                end

          [http_method, uri]
        end

        def target_from(action, light_id, group_id)
          case
          when group_id && light_id then fail "Must specify 0 or 1 of [light_id, group_id]!"
          when group_id             then [:group, group_id]
          when light_id             then [:light, light_id]
          when action == :create    then [:group]
          else                           [:bridge]
          end
        end

        STATUS_EXP      = %r{\AHTTP/(\d+\.\d+) (?<code>\d+)}
        QUERY_SCOPE     = { light: "lights", group: "groups" }
        ACTION_ENDPOINT = { light: "state", group: "action" }
        HTTP_METHODS    = { query:     "GET",
                            configure: "PUT",
                            update:    "PUT",
                            delete:    "DELETE",
                            create:    "POST" }

        def query_uri(target, target_id)
          base = "/api/#{bridge['username']}"
          scope = QUERY_SCOPE[target]
          scope ? (target_id ? "#{base}/#{scope}/#{target_id}" : "#{base}/#{scope}") : base
        end

        def update_uri(target, target_id)
          fail "Can't update a bridge!" if target == :bridge
          "#{query_uri(target, target_id)}/#{ACTION_ENDPOINT[target]}"
        end
      end

      def with_transition_time(transition, data)
        # This allows you to specify transition time in seconds, as a float instead of the awkward
        # tenths-of-a-second actually supported by the bridge.
        data["transitiontime"] = (transition * 10.0).round(0)
        data
      end

      def request(bridge, action, group_id: nil, light_id: nil, payload: nil, transition: nil,
                  &callback)
        payload = with_transition_time(transition, payload) if payload && transition
        NetHTTPRequest.new(bridge, action, light_id: light_id, group_id: group_id, payload: payload,
                           &callback)
      end

      def bridge_query(bridge, &callback)
        request(bridge, :query, &callback)
      end

      def bridge_modify(bridge, payload: nil, &callback)
        request(bridge, :configure, payload: payload, &callback)
      end

      def light_update(bridge, light_id, payload: nil, transition: nil, &callback)
        request(bridge, :update, light_id: light_id, payload: payload, transition: transition,
                &callback)
      end

      def light_modify(bridge, light_id, payload: nil, &callback)
        request(bridge, :configure, light_id: light_id, payload: payload, &callback)
      end

      def group_update(bridge, group_id, payload: nil, transition: nil, &callback)
        request(bridge, :update, group_id: group_id, payload: payload, transition: transition,
                &callback)
      end

      def group_modify(bridge, group_id, payload: nil, &callback)
        request(bridge, :configure, group_id: group_id, payload: payload, &callback)
      end

      def group_create(bridge, payload: nil, &callback)
        request(bridge, :create, payload: payload, &callback)
      end

      def group_delete(bridge, group_id, &callback)
        request(bridge, :delete, group_id: group_id, &callback)
      end

      def perform_once(requests, &callback)
        failures = []
        requests.each do |request|
          perform_request(request, failures, &callback)
        end
        failures
      end

      def perform_request(request, failures, &callback)
        error, status, body = request.perform
        if error
          LOGGER.error { "#{request.uri} => #{status} / #{body.join("\n")}" }
          failures << request
          next
        end

        callback.call(request, status, body) if block_given?
      rescue StandardError => se
        LOGGER.error { "Exception handling request to: #{request.uri}" }
        LOGGER.error { se }
      end

      def perform_with_retries(requests, max_retries: nil, &callback)
        retries = 0
        while requests.length > 0
          failures = requests = perform_once(requests, &callback)
          break if max_retries && retries >= max_retries
          retries += 1
          sleep 0.05 * (2**retries) if requests.length > 0
        end
        failures
      end
    end
  end
end
