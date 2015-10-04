module SparkleMotion
  module Hue
    # Helpers for SSDP discovery of bridges.
    class SSDP
      def scan
        raw = Frisky::SSDP
              .search("IpBridge", ttl: 30)
              .select { |resp| ssdp_response?(resp) }
              .map { |resp| ssdp_extract(resp) }
              .select { |resp| resp["name"] == "upnp:rootdevice" }
        Hash[raw.map { |resp| [resp["ipaddress"], resp["id"]] }]
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
        { "id"        => usn_to_id(resp[:usn]),
          "name"      => resp[:st],
          "ipaddress" => URI.parse(resp[:location]).host }
      end

      def usn_to_id(usn); usn.split(/:/, 3)[1].split(/-/).last; end
    end
  end
end
