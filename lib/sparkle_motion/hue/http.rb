require "oj"
require "socket"

module SparkleMotion
  module Hue
    # Helpers for interacting with the Philips Hue Bridge.
    module HTTP
      # Class to encapsulate a request to the Hue Bridge
      class Request
        attr_reader :bridge, :action, :light_id, :group_id, :http_method, :uri, :payload

        def initialize(bridge, action, light_id: nil, group_id: nil, payload: nil, &callback)
          @bridge             = bridge
          @action             = action
          @payload            = payload
          @target, @target_id = target_from(light_id, group_id)
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

          socket.puts(message)
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
          if http_method == "GET"
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
                        else
                          fail "Unknown action '#{action}'!"
                        end

          uri = (action == :update) ? update_uri(target, target_id) : query_uri(target, target_id)

          [http_method, uri]
        end

        def target_from(light_id, group_id)
          case
          when group_id && light_id then fail "Must specify 0 or 1 of [light_id, group_id]!"
          when group_id             then [:group, group_id]
          when light_id             then [:light, light_id]
          else                           [:bridge]
          end
        end

        STATUS_EXP      = %r{\AHTTP/(\d+\.\d+) (?<code>\d+)}
        QUERY_SCOPE     = { light: "lights", group: "groups" }
        ACTION_ENDPOINT = { light: "state", group: "action" }

        def query_uri(target, target_id)
          base = "/api/#{bridge['username']}"
          scope = QUERY_SCOPE[target]
          scope ? "#{base}/#{scope}/#{target_id}" : base
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
        Request.new(bridge, action, light_id: light_id, group_id: group_id, payload: payload,
                    &callback)
      end

      def bridge_query(bridge, &callback)
        request(bridge, :query, &callback)
      end

      def light_update(bridge, light_id, payload: nil, transition: nil, &callback)
        request(bridge, :update, light_id: light_id, payload: payload, transition: transition,
                &callback)
      end

      def light_modify(bridge, light_id, payload: nil, transition: nil, &callback)
        request(bridge, :configure, light_id: light_id, payload: payload, transition: transition,
                &callback)
      end

      def group_update(bridge, group_id, payload: nil, transition: nil, &callback)
        request(bridge, :update, group_id: group_id, payload: payload, transition: transition,
                &callback)
      end

      def group_modify(bridge, group_id, payload: nil, transition: nil, &callback)
        request(bridge, :configure, group_id: group_id, payload: payload, transition: transition,
                &callback)
      end

      def perform_once(requests, &callback)
        failures = []
        requests.each do |request|
          begin
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
        end
        failures
      end

      def perform_with_retries(requests, max_retries: nil, &callback)
        retries = 0
        while requests.length > 0
          failures = requests = perform_once(requests, &callback)
          break if max_retries && retries >= max_retries
          retries += 1
          sleep 0.5 * (2**retries) if requests.length > 0
        end
        failures
      end
    end
  end
end
