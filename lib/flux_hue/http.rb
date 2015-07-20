require "net/http"
require "oj"
Oj.default_options = { mode: :strict }

module FluxHue
  # Helpers for Hue Bridge REST requests.  Placeholder to accrue redundant code
  # in order to DRY things up, centralize response handling, and prepare for
  # a more streamlined approach to interacting with the bridge.
  class HTTP
    def get(url); Oj.load(Net::HTTP.get(URI.parse(url))); end
    def post(url, data); perform(:request_post, url, data); end
    def put(url, data); perform(:request_put, url, data); end

    def delete(url)
      uri, http = setup(url)
      JSON(http.delete(uri.path).body)
    end

    def successes(resp)
      resp
        .select { |rr| rr.key?("success") }
        .map { |rr| rr["success"] }
    end

  private

    def setup(url, data = nil)
      uri   = URI.parse(url)
      data  = Oj.dump(data) if data
      [uri, Net::HTTP.new(uri.host, uri.port), data]
    end

    def perform(method, url, data)
      uri, http, data = setup(url, data)

      Oj.load(http.send(method, uri.path, data).body)
    end
  end
end
