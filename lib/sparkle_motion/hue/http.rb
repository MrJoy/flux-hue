require "curb"
require "oj"

module SparkleMotion
  module Hue
    # Helpers for interacting with the Philips Hue Bridge.
    module HTTP
      # TODO: Try to figure out how to set Curl::CURLOPT_TCP_NODELAY => true
      # TODO: Disable Curl from sending keepalives by trying HTTP/1.0.
      MULTI_OPTIONS = { pipeline:     false,
                        max_connects: (CONFIG["max_connects"] || 3) }
      EASY_OPTIONS = { "timeout"           => 5,
                       "connect_timeout"   => 5,
                       "follow_location"   => false,
                       "max_redirects"     => 0,
                       "dns_cache_timeout" => -1 } # ,
                       # version:          Curl::HTTP_1_0 }
      #   easy.header_str.grep(/keep-alive/)
      # Force keepalive off to see if that makes any difference...
      # TODO: Use this: `easy.headers["Expect"] = ''` to remove default header we don't care about!

      def query_struct(url)
        { method: :get,
          url:    url }.merge(SparkleMotion::Hue::HTTP::EASY_OPTIONS)
      end

      def update_struct(url, data)
        { method:   :put,
          url:      url,
          put_data: Oj.dump(data) }.merge(SparkleMotion::Hue::HTTP::EASY_OPTIONS)
      end

      def with_transition_time(transition, data)
        # This allows you to specify transition time in seconds, as a float instead of the awkward
        # tenths-of-a-second actually supported by the bridge.
        data["transitiontime"] = (transition * 10.0).round(0)
        data
      end

      def endpoint_url(bridge); "http://#{bridge['ip']}"; end

      def bridge_query_url(bridge); "#{endpoint_url(bridge)}/api/#{bridge['username']}"; end
      def light_query_url(bridge, light_id); "#{bridge_query_url(bridge)}/lights/#{light_id}"; end
      def group_query_url(bridge, group_id); "#{bridge_query_url(bridge)}/groups/#{group_id}"; end

      # def bridge_update_url(bridge); "#{bridge_query_url(bridge)}/?????"; end
      def light_update_url(bridge, light_id); "#{light_query_url(bridge, light_id)}/state"; end
      def group_update_url(bridge, group_id); "#{group_query_url(bridge, group_id)}/action"; end

      def request(bridge, http_method, url, payload, transition, &callback)
        payload = with_transition_time(transition, payload) if payload && transition
        LazyRequestConfig.new(SparkleMotion.logger, bridge, http_method, url) do
          if block_given?
            callback.call
          else
            payload
          end
        end
      end

      def bridge_query(bridge, &callback)
        url = bridge_query_url(bridge)
        request(bridge, :get, url, nil, nil, &callback)
      end

      def light_update(bridge, light_id, payload: nil, transition: nil, &callback)
        url = light_update_url(bridge, light_id)
        request(bridge, :put, url, payload, transition, &callback)
      end

      def group_update(bridge, group_id, payload: nil, transition: nil, &callback)
        url = group_update_url(bridge, group_id)
        request(bridge, :put, url, payload, transition, &callback)
      end

      def perform_once(requests, options: nil, &callback)
        # Lookup map is so we can find the original `LazyRequestConfig` by the request URL.
        # TODO: Can we maybe find a way around needing this damn lookup table?
        reqs = Hash[requests.map { |req| [req.url, req] }]
        opts = SparkleMotion::Hue::HTTP::MULTI_OPTIONS
        opts = opts.merge(options) if options
        failures = []
        Curl::Multi.http(requests, opts) do |easy|
          url = easy.url
          if easy.response_code != 200 || easy.body =~ /error/
            LOGGER.error { "#{url} => #{easy.response_code} / #{easy.body}" }
            failures << reqs[url]
          end
          if block_given?
            begin
              callback.call(easy, reqs[url])
            rescue StandardError => se
              LOGGER.error { "Exception handling request to: #{url}" }
              LOGGER.error { se }
            end
          end
        end
        failures
      end

      def perform_with_retries(requests, max_retries: nil, options: nil, &callback)
        retries = 0
        while requests.length > 0
          failures = requests = perform_once(requests, options: options, &callback)
          break if max_retries && retries >= max_retries
          retries += 1
          sleep 0.5 * (2**retries) if requests.length > 0
        end
        failures
      end
    end
  end
end
