require "date"

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
      define_method(prop) do
        instance_variable_get("@#{prop}") || @bridge.send(prop)
      end
    end

    # HTTP/REST agent.
    def agent; @bridge.agent; end

    # Various properties from the bridge that require a registered `username`
    # to read.
    attr_reader :username, :zigbee_channel, :software_update, :network_mask,
                :gateway, :known_clients, :portal_state

    def software_update_summary; (software_update || {})["text"]; end
    def dhcp?; @dhcp; end
    def portal_services?; @portal_services; end
    def portal_connection?; @portal_connection; end
    def link_button?; @link_button; end
    def proxy_address; @proxy_address == "none" ? nil : @proxy_address; end
    def proxy_port; @proxy_port == 0 ? nil : @proxy_port; end
    def utc; DateTime.parse(fetch_configuration["utc"]); end

    def initialize(bridge, username: nil)
      effective_username  = determine_effective_username(username)
      validate_username!(effective_username)

      @bridge             = bridge
      @username           = effective_username

      begin
        validate_user!
      rescue UnauthorizedUser
        @bridge.register_user!(effective_username)
      end
    end

    def lights; @lights ||= fetch_entities("#{url}/lights", Light); end
    def groups; @groups ||= fetch_entities("#{url}/groups", Group); end
    def scenes; @scenes ||= fetch_entities("#{url}/scenes", Scene); end

    # TODO: Add support for specifying serial numbers.
    def add_lights
      agent.post("#{@client.url}/lights", nil).first
    end

    def light(id)
      lights.find { |l| l.id == id }
    end

    def group(id)
      groups.find { |g| g.id == id }
    end

    def scene(id)
      scenes.find { |s| s.id == id }
    end

    def url; "#{@bridge.url}/#{username}"; end

    def refresh!
      unpack(fetch_configuration)
      self
    end

  private

    def fetch_entities(collection_url, entity_class)
      agent
        .get(collection_url)
        .map { |id, dd| entity_class.new(client: self, id: id.to_i, data: dd) }
    end

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

    def validate_user!
      response = agent.get(state_url)
      response = response.first if response.is_a?(Array)

      handle_error!(response["error"])

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
