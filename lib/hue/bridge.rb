module Hue
  # Functionality common to all bridge interfaces.
  module BridgeShared
    include TranslateKeys

    def unpack(hash)
      unpack_hash(hash, keys_map)
      @id = @mac_address.gsub(/:/, "") if !@id && @mac_address
    end

    def fetch_configuration
      JSON(Net::HTTP.get(URI.parse("#{url}/config")))
    end
  end

  # A `Bridge` represents a bridge, without a `username` for accessing
  # non-public or restricted functionality.  Very little can be done/accessed
  # without a `username`, but what there is is made available here.
  #
  # Principally, this includes bridge discovery
  class Bridge
    include BridgeShared

    # ID of the bridge.
    attr_reader :id

    # Name of the bridge. This is also its uPnP name, so will reflect the
    # actual uPnP name after any conflicts have been resolved.
    attr_reader :name

    # MAC address of the bridge.
    attr_reader :mac_address

    # Which API version the bridge is serving, given its current firmware
    # version.
    attr_reader :api_version

    # Software version of the bridge.
    attr_reader :software_version

    # IP address of the bridge.
    attr_reader :ip

    def initialize(hash)
      unpack(hash)
    end

    def refresh!; unpack(fetch_configuration); end

    def url; "http://#{ip}/api"; end

    # Find all bridges.
    #
    # * If `ip` is specified, or `HUE_BRIDGE_IP` is set, a `Bridge` will be
    #   returned for that IP, and generally discovery will be skipped.
    # * If `force_discovery` is set, then discovery will be performed *in
    #   addition to* using the explicit IP.
    def self.all(ip: nil, force_discovery: false)
      @all ||= begin
        eff_ip        = determine_effective_ip(ip)

        bridges       = []
        bridges      += [Bridge.new("ipaddress" => eff_ip)] if eff_ip
        # TODO: Perhaps, given the use-case it supports, we want to do ALL
        # TODO: discovery searches when `force_discovery` is present?
        bridges      += find_by_discovery if !eff_ip || force_discovery

        filter_bridges(bridges)
      end
    end

    def self.find_by_discovery
      bridges = find_by_ssdp
      bridges = find_by_nupnp unless bridges.length > 0

      filter_bridges(bridges)
    end

    def self.find_by_ssdp
      return [] if ENV["HUE_SKIP_SSDP"] && ENV["HUE_SKIP_SSDP"] != ""
      # TODO: Ensure we're *only* getting things we want here!  The Hue Bridge
      # TODO: tends to be obnoxious and announce itself on *any* SSDP request,
      # TODO: so we may encounter other obnoxious gear as well...
      puts "INFO: Discovering bridges via SSDP..."

      setup_ssdp_lib!
      bridges     = Playful::SSDP.search("IpBridge")
                    .select { |resp| bridge_ssdp_response?(resp) }
                    .map do |resp|
                      Bridge.new("id"        => usn_to_id(resp[:usn]),
                                 "name"      => resp[:st],
                                 "ipaddress" => URI.parse(resp[:location]).host)
                    end

      filter_bridges(bridges)
    end

    NUPNP_URL = "https://www.meethue.com/api/nupnp"

    def self.find_by_nupnp
      return [] if ENV["HUE_SKIP_NUPNP"] && ENV["HUE_SKIP_NUPNP"] != ""
      puts "INFO: Discovering bridges via N-UPnP..."
      # UPnP failed, lets use N-UPnP
      bridges = []
      JSON(Net::HTTP.get(URI.parse(NUPNP_URL))).each do |hash|
        # Normalize our interface a bit...
        hash["ipaddress"] = hash.delete("internalipaddress")
        # The N-UPnP interface delivers an ID which is (apparently) the MAC
        # address, with two bytes injected in the middle.  To keep IDs sane
        # regardless of where we got them (NUPnP vs. SSDP), we just reduce it
        # to the MAC address.
        raw_id      = hash["id"]
        hash["id"]  = raw_id[0..5] + raw_id[10..15] if raw_id

        bridges << Bridge.new(hash)
      end

      filter_bridges(bridges)
    end

    def keys_map; KEYS_MAP; end

  private

    KEYS_MAP = {
      id:               :id,
      name:             :name,
      mac_address:      :mac,
      api_version:      :apiversion,
      software_version: :swversion,

      ip:               :ipaddress,
    }

    # Loads the Playful library for SSDP late to avoid slowing down the CLI
    # needlessly when SSDP isn't needed.
    def self.setup_ssdp_lib!
      require "playful/ssdp" unless defined?(Playful)
      Playful.log = false # Playful is super verbose
    end

    # Ensure we're *only* getting responses from a Philips Hue bridge.  The
    # Hue Bridge tends to be obnoxious and announce itself on *any* SSDP
    # SSDP request, so we assume that we may encounter other obnoxious gear
    # as well...
    def self.bridge_ssdp_response?(resp)
      (resp[:server] || "")
        .split(/[,\s]+/)
        .find { |token| token =~ %r{\AIpBridge/\d+(\.\d+)*\z} }
    end

    def self.determine_effective_ip(explicit_ip)
      ip_var        = ENV["HUE_BRIDGE_IP"]
      have_ip_var   = ip_var && ip_var != ""
      explicit_ip || (have_ip_var ? ip_var : nil)
    end

    def self.filter_bridges(bridges)
      bridges
        .sort { |a, b| a.ip <=> b.ip }
        .uniq(&:ip)
        .uniq
    end

    # TODO: With all the hassle around ID and the fact that I'm essentially
    # TODO: coercing it down to just MAC address....  Just use the damned IP
    # TODO: or MAC!
    def self.usn_to_id(usn); usn.split(/:/, 3)[1].split(/-/).last; end
  end
end
