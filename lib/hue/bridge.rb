module Hue
  class Bridge
    # ID of the bridge.
    attr_reader :id

    # Name of the bridge. This is also its uPnP name, so will reflect the
    # actual uPnP name after any conflicts have been resolved.
    attr_reader :name

    # The Zigbee channel the bridge is using.
    attr_reader :zigbee_channel

    # MAC address of the bridge.
    attr_reader :mac_address

    # Which API version the bridge is serving, given its current firmware
    # version.
    attr_reader :api_version

    # Software version of the bridge.
    attr_reader :software_version

    # Contains information related to software updates.
    attr_reader :software_update

    def software_update_summary; (software_update || {})["text"]; end

    # Indicates whether the link button has been pressed within the last 30
    # seconds.
    def link_button?; get_configuration['linkbutton']; end

    # IP address of the bridge.
    attr_reader :ip

    # Network mask of the bridge.
    attr_reader :network_mask

    # Gateway IP address of the bridge.
    attr_reader :gateway

    # Whether the IP address of the bridge is obtained with DHCP.
    attr_reader :dhcp

    # IP Address of the proxy server being used.
    attr_reader :proxy_address

    # Port of the proxy being used by the bridge. If set to 0 then a proxy is
    # not being used.
    attr_reader :proxy_port

    # An array of whitelisted (known) clients.
    attr_reader :known_clients

    # This indicates whether the bridge is registered to synchronize data with
    # a portal account.
    def portal_services?; get_configuration['portalservices']; end
    def portal_connection; get_configuration['portalconnection']; end
    def portal_state; get_configuration['portalstate']; end

    def initialize(client, hash)
      @client = client
      unpack(hash)
    end

    # Current time stored on the bridge.
    def utc; DateTime.parse(get_configuration['utc']); end

    def refresh; unpack(get_configuration); end

    def url; "http://#{ip}/api"; end

  private

    KEYS_MAP = {
      :id                 => :id,
      :name               => :name,
      :zigbee_channel     => :zigbeechannel,
      :mac_address        => :mac,
      :api_version        => :apiversion,
      :software_version   => :swversion,
      :software_update    => :swupdate,
      :link_button        => :linkbutton,

      :ip                 => :ipaddress,
      :network_mask       => :netmask,
      :gateway            => :gateway,
      :dhcp               => :dhcp,
      :proxy_address      => :proxyaddress,
      :proxy_port         => :proxyport,

      :known_clients      => :whitelist,
      # :portal_services    => :portalservices,
      # :portal_connection  => :portalconnection,
      # :portal_state       => :portalstate,
    }

    def unpack(hash)
      KEYS_MAP.each do |local_key, remote_key|
        value = hash[remote_key.to_s]
        next unless value
        instance_variable_set("@#{local_key}", value)
      end
    end

    def get_configuration
      # Make us a bit more loosely coupled -- ideally Bridge wouldnt know about
      # client, but...  Bleah.  In the meantime, prefer the client base URL if
      # we DO have a client so we can get more info from the hub like the
      # ZigBee channel, and such.
      config_url_base = @client ? @client.url : url
      JSON(Net::HTTP.get(URI.parse("#{config_url_base}/config")))
    end
  end
end
