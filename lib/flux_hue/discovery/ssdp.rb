module FluxHue
  module Discovery
    # Helpers for SSDP discovery of bridges.
    module SSDP
      def ssdp_scan!
        setup_ssdp_lib!
        Playful::SSDP
          .search("IpBridge")
          .select { |resp| ssdp_response?(resp) }
          .map { |resp| ssdp_extract(resp) }
      end

      # Loads the Playful library for SSDP late to avoid slowing down the CLI
      # needlessly when SSDP isn't needed.
      def setup_ssdp_lib!
        require "playful/ssdp" unless defined?(Playful)
        Playful.log = false # Playful is super verbose
      end

      # Ensure we're *only* getting responses from a Philips Hue bridge.  The
      # Hue Bridge tends to be obnoxious and announce itself on *any* SSDP
      # SSDP request, so we assume that we may encounter other obnoxious gear
      # as well...
      def ssdp_response?(resp)
        (resp[:server] || "")
          .split(/[,\s]+/)
          .find { |token| token =~ %r{\AIpBridge/\d+(\.\d+)*\z} }
      end

      def ssdp_extract(resp)
        {
          "id"        => ssdp_usn_to_id(resp[:usn]),
          "name"      => resp[:st],
          "ipaddress" => URI.parse(resp[:location]).host,
        }
      end

      # TODO: With all the hassle around ID and the fact that I'm essentially
      # TODO: coercing it down to just MAC address....  Just use the damned IP
      # TODO: or MAC!
      def ssdp_usn_to_id(usn); usn.split(/:/, 3)[1].split(/-/).last; end
    end
  end
end
