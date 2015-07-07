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

    # Indicates whether the link button has been pressed within the last 30
    # seconds.
    def link_button?
      json = get_configuration
      json['linkbutton']
    end

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

    # This indicates whether the bridge is registered to synchronize data with a
    # portal account.
    def portal_services?
      json = get_configuration
      json['portalservices']
    end

    def portal_connection
      json = get_configuration
      json['portalconnection']
    end

    def portal_state
      json = get_configuration
      json['portalstate']
    end

    def initialize(client, hash)
      @client = client
      unpack(hash)
    end

    # Current time stored on the bridge.
    def utc
      json = get_configuration
      DateTime.parse(json['utc'])
    end

    def refresh
      json = get_configuration
      unpack(json)
    end

    def lights
      @lights ||= begin
        json = JSON(Net::HTTP.get(URI.parse(base_url)))
        json['lights'].map do |key, value|
          Light.new(@client, self, key, value)
        end
      end
    end

    def add_lights
      uri = URI.parse("#{base_url}/lights")
      http = Net::HTTP.new(uri.host)
      response = http.request_post(uri.path, nil)
      JSON(response.body).first
    end

    def groups
      @groups ||= begin
        json = JSON(Net::HTTP.get(URI.parse("#{base_url}/groups")))
        json.map do |id, data|
          Group.new(@client, self, id, data)
        end
      end
    end

    def scenes
      @scenes ||= begin
        json = JSON(Net::HTTP.get(URI.parse("#{base_url}/scenes")))
        json.map do |id, data|
          Scene.new(@client, self, id, data)
        end
      end
    end

  private

    KEYS_MAP = {
      :id                 => :id,
      :name               => :name,
      :zigbee_channel     => :zigbeechannel,
      :mac_address        => :mac,
      :api_version        => :apiversion,
      :software_version   => :swversion,
      :software_update    => :swupdate,
      # :link_button        => :linkbutton,

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
      JSON(Net::HTTP.get(URI.parse("#{base_url}/config")))
    end

    def base_url
      "http://#{ip}/api/#{@client.username}"
    end
  end
end
