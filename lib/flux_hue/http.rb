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
  end
end
