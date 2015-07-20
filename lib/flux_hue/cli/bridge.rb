module FluxHue
  module CLI
    # CLI functionality for managing bridges.
    class Bridge < Base
      DISCOVER_FIELDS = {
        id:               "ID",
        name:             "Name",
        ip:               "IP",
        mac_address:      "MAC",
        api_version:      "API Version",
        software_version: "Software Version",
      }

      desc "discover", "Find all the bridges on your network"
      shared_bridge_options
      def discover
        # TODO: Extended output form that includes proxy_address, proxy_port,
        # TODO: known_clients, network_mask, gateway, dhcp, etc...
        bridges = FluxHue::Bridge.all(ip: options[:ip], force_discovery: true)
        rows    = bridges
                  .map { |bridge| extract_fields(bridge, DISCOVER_FIELDS) }

        puts render_table(rows, DISCOVER_FIELDS)
      end

      # TODO: Coalesce proxy_address and proxy_port, but filter magic `none`
      # TODO: value...
      INSPECT_FIELDS = {
        id:                       "ID",
        ip:                       "IP",
        mac_address:              "MAC",

        name:                     "Name",
        zigbee_channel:           "Channel",
        network_mask:             "Net Mask",
        gateway:                  "Gateway",
        dhcp:                     "DHCP?",
        proxy_address:            "Proxy Address",
        proxy_port:               "Proxy Port",

        portal_services?:         "Portal Services?",
        portal_connection:        "Connected to Portal?",
        portal_state:             "Portal State",

        api_version:              "API Version",
        software_version:         "Software Version",
        software_update_summary:  "Update Info",

        link_button?:             "Button?",
      }

      desc "inspect [--ip=<bridge IP>]",
           "Show information about the selected bridge"
      long_desc <<-LONGDESC
        This is most useful in conjunction with --ip or HUE_BRIDGE_IP, if you
          have multiple bridges.\n
        Examples:\n
          hue bridge inspect\n
          hue bridge inspect --ip 1.2.3.4\n
      LONGDESC
      shared_bridge_options
      def inspect
        # TODO: Command to get known_clients, etc...

        rows = [extract_fields(client, INSPECT_FIELDS)]

        puts render_table(pivot_row(rows, INSPECT_FIELDS))
      end

    private

      def pivot_row(rows, mapping)
        mapping.values.zip(rows.first)
      end

      def render_table(rows, mapping = nil)
        params            = { rows: rows }
        params[:headings] = mapping.values if mapping

        Terminal::Table.new(params)
      end

      def extract_fields(entity, mapping)
        # TODO: Make this happen on-demand when accessing a property that
        # TODO: isn't populated yet.
        entity.refresh!
        mapping.keys.map { |prop| entity.send(prop) }
      end
    end
  end
end
