module FluxHue
  module CLI
    # Helper to cleanse and format data from a Bridge/Client for display.
    class BridgePresenter < Presenter
      def_delegators :@entity, :id, :ip, :mac_address, :name, :zigbee_channel,
                     :network_mask, :gateway, :dhcp, :portal_connection,
                     :portal_state, :api_version, :software_version,
                     :software_update_summary
      boolean :dhcp?, :portal_services?, :portal_connection?, :link_button?

      def proxy
        [@entity.proxy_address, @entity.proxy_port].compact.join(":")
      end
    end

    # CLI functionality for managing bridges.
    class Bridge < Base
      DISCOVER_FIELDS = {
        id:               "ID",
        ip:               "IP",
        mac_address:      "MAC",

        name:             "Name",

        api_version:      "API Version",
        software_version: "Software Version",
      }

      desc "discover", "Find all the bridges on your network"
      shared_bridge_options
      def discover
        bridges = FluxHue::Bridge.all(ip: options[:ip], force_discovery: true)
        rows    = bridges
                  .map(&:refresh!)
                  .map { |bridge| extract_fields(bridge, DISCOVER_FIELDS) }

        puts render_table(rows, DISCOVER_FIELDS)
      end

      # TODO: Coalesce proxy_address and proxy_port, but filter magic `none`
      # TODO: value...
      INSPECT_FIELDS = {
        id:                       "ID",
        ip:                       "IP Address",
        mac_address:              "MAC Address",

        name:                     "Name",
        zigbee_channel:           "ZigBee Channel",
        network_mask:             "Net Mask",
        gateway:                  "Gateway",
        dhcp?:                    "Using DHCP?",
        proxy:                    "Proxy Configuration",

        portal_services?:         "Portal Services?",
        portal_connection?:       "Connected to Portal?",
        portal_state:             "Portal State",

        api_version:              "API Version",
        software_version:         "Software Version",
        software_update_summary:  "Update Info",

        link_button?:             "Button Pressed?",
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

        client.refresh!
        rows = [extract_fields(BridgePresenter.new(client), INSPECT_FIELDS)]

        puts render_table(pivot_row(rows, INSPECT_FIELDS))
      end
    end
  end
end
