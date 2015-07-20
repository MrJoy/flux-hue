require "date"
require "net/http"
require "json"

module FluxHue
  # A `Client` represents a bridge, with a `username` for accessing non-public
  # or restricted functionality.  In most cases, this is what you want, as
  # very little is possible on the bridge without a `username`.
  class Client
    include BridgeShared

    # By default we just use a made up username when talking to the client.
    # For simple cases where you only have one bridge (and aren't using
    # software by someone who thought of the same clever name) this makes it so
    # you don't need to store/manage any configuration -- it just happens
    # automatically.
    DEFAULT_USERNAME = "1234567890"

    # In order to make this class work (largely) as a superset of `Bridge`, we
    # proxy some methods through to an instance of `Bridge` that we're handed
    # at construction-time.  When we make an API call to refresh ourselves,
    # we'll wind up picking up much the same data, so we want to ensure that
    # our version takes precedence in order to avoid having to push state into
    # the `Bridge`, force a redundant refresh of it, or force the user to do
    # so.
    Bridge::KEYS_MAP.keys.each do |prop|
      define_method prop do
        instance_variable_get(:"@#{prop}") || @bridge.send(prop)
      end
    end

    # The username registered with the bridge that we'll connect as.
    attr_reader :username

    # The Zigbee channel the bridge is using as of when `refresh! was last
    # called.
    attr_reader :zigbee_channel

    # Contains information related to software updates as of when `refresh! was
    # last called.
    attr_reader :software_update

    def software_update_summary; (software_update || {})["text"]; end

    # Indicates whether the link button had been pressed within the 30 seconds
    # prior to when `refresh! was last called.
    def link_button?; @link_button; end

    # Network mask of the bridge as of when `refresh! was last called.
    attr_reader :network_mask

    # Gateway IP address of the bridge as of when `refresh! was last called.
    attr_reader :gateway

    # Whether the IP address of the bridge is obtained with DHCP as of when
    # `refresh! was last called.
    attr_reader :dhcp

    # IP Address of the proxy server being used as of when `refresh! was last
    # called.
    def proxy_address; @proxy_address == "none" ? nil : @proxy_address; end

    # Port of the proxy being used by the bridge as of when `refresh! was last
    # called.
    def proxy_port; @proxy_port == 0 ? nil : @proxy_port; end

    # An array of whitelisted (known) clients as of when `refresh! was last
    # called.
    attr_reader :known_clients

    # This indicates whether the bridge was registered to synchronize data with
    # a portal account as of when `refresh! was last called.
    def portal_services?; @portal_services; end

    # Whether or not the bridge was connected to the Philips portal as of when
    # `refresh! was last called.
    attr_reader :portal_connection

    # The state of the Philips portal as of when `refresh! was last called.
    attr_reader :portal_state

    # Current time stored on the bridge.
    def utc; DateTime.parse(fetch_configuration["utc"]); end

    def initialize(bridge, username: nil)
      effective_username  = determine_effective_username(username)
      validate_username!(effective_username)

      @bridge             = bridge
      @username           = effective_username

      begin
        validate_user!
      rescue UnauthorizedUser
        register_user!
      end
    end

    def lights
      @lights ||= JSON(Net::HTTP.get(URI.parse(url)))["lights"]
                  .map { |id, dd| Light.new(client: self, id: id, data: dd) }
    end

    def groups
      @groups ||= JSON(Net::HTTP.get(URI.parse("#{url}/groups")))
                  .map { |id, dd| Group.new(client: self, id: id, data: dd) }
    end

    def scenes
      @scenes ||= JSON(Net::HTTP.get(URI.parse("#{url}/scenes")))
                  .map { |id, dd| Scene.new(client: self, id: id, data: dd) }
    end

    # TODO: Add support for specifying serial numbers.
    def add_lights
      uri = URI.parse("#{@client.url}/lights")
      http = Net::HTTP.new(uri.host)
      response = http.request_post(uri.path, nil)
      JSON(response.body).first
    end

    def light(id)
      id = id.to_s
      lights.find { |l| l.id == id }
    end

    def group(id)
      id = id.to_s
      groups.find { |g| g.id == id }
    end

    def scene(id)
      id = id.to_s
      scenes.find { |s| s.id == id }
    end

    def url; "#{@bridge.url}/#{username}"; end

    def refresh!; unpack(fetch_configuration); end

    def keys_map; KEYS_MAP; end

  private

    NAME_RANGE      = 10..40
    NAME_RANGE_MSG  = "Usernames must be between #{NAME_RANGE.first} and"\
                      " #{NAME_RANGE.last}."

    def validate_username!(username)
      fail InvalidUsername, NAME_RANGE_MSG unless NAME_RANGE
                                                  .include?(username.length)
    end

    def determine_effective_username(explicit_username)
      username_var  = ENV["HUE_BRIDGE_USER"]
      have_var      = username_var && username_var != ""

      explicit_username || (have_var ? username_var : DEFAULT_USERNAME)
    end

    # TODO: Prepopulate things with the response here, as we just pulled down
    # TODO: *everything* about the current state of the bridge!
    def validate_user!
      response  = JSON(Net::HTTP.get(URI.parse(url)))
      response  = response.first if response.is_a? Array
      error     = response["error"]

      fail Hue.get_error(error) if error

      response["success"]
    end

    def register_user!
      # TODO: Better devicetype value, and allow customizing it!
      data = {
        devicetype: "Ruby",
        username:   username,
      }

      uri       = URI.parse(bridge.url)
      http      = Net::HTTP.new(uri.host)
      response  = JSON(http.request_post(uri.path, JSON.dump(data)).body).first
      error     = response["error"]

      fail Hue.get_error(error) if error

      response["success"]
    end

    CLIENT_KEYS_MAP = {
      zigbee_channel:     :zigbeechannel,
      software_update:    :swupdate,

      link_button:        :linkbutton,
      known_clients:      :whitelist,

      network_mask:       :netmask,
      gateway:            :gateway,
      dhcp:               :dhcp,
      proxy_address:      :proxyaddress,
      proxy_port:         :proxyport,

      portal_services:    :portalservices,
      portal_connection:  :portalconnection,
      portal_state:       :portalstate,
    }
    KEYS_MAP = Bridge::KEYS_MAP.merge(CLIENT_KEYS_MAP)
  end
end
