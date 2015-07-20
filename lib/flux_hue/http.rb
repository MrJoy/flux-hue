require "net/http"
require "json"

module FluxHue
  # Helpers for Hue Bridge REST requests.  Placeholder to accrue redundant code
  # in order to DRY things up, centralize response handling, and prepare for
  # a more streamlined approach to interacting with the bridge.
  class HTTP
    def get(url)
      JSON(Net::HTTP.get(URI.parse(url)))
    end

    def post(url, data); perform(:request_post, url, data); end
    def put(url, data); perform(:request_put, url, data); end

  private

    def perform(method, url, data)
      uri       = URI.parse(url)
      http      = Net::HTTP.new(uri.host)
      data      = JSON.dump(data) if data

      JSON(http.send(method, uri.path, data).body)
    end
  end
end
