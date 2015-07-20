module FluxHue
  module Discovery
    # Helpers for N-UPnP discovery of bridges.
    module NUPnP
      NUPNP_URL = "https://www.meethue.com/api/nupnp"

      def nupnp_scan!
        agent.get(NUPNP_URL).map { |resp| nupnp_extract(resp) }
      end

      def nupnp_extract(resp)
        resp              = resp.dup
        # Normalize our interface a bit...
        resp["ipaddress"] = resp.delete("internalipaddress")
        # The N-UPnP interface delivers an ID which is (apparently) the MAC
        # address, with two bytes injected in the middle.  To keep IDs sane
        # regardless of where we got them (NUPnP vs. SSDP), we just reduce it
        # to the MAC address.
        resp["id"]        = nupnp_uuid_to_id(resp["id"])
        resp
      end

      def nupnp_uuid_to_id(raw_id)
        raw_id ? raw_id[0..5] + raw_id[10..15] : nil
      end
    end
  end
end
