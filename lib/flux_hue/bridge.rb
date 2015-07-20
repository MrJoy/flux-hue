module FluxHue
  # A `Bridge` represents a bridge, without a `username` for accessing
  # non-public or restricted functionality.  Very little can be done/accessed
  # without a `username`, but what there is is made available here.
  #
  # Principally, this includes bridge discovery
  class Bridge
    include BridgeShared

    # HTTP/REST agent.
    attr_reader :agent

    # Various properties from the bridge that can be accessed freely.
    attr_reader :id, :name, :mac_address, :api_version, :software_version, :ip

    def initialize(agent, hash)
      @agent = agent
      unpack(hash)
    end

    def refresh!; unpack(fetch_configuration); end

    def url; "http://#{ip}/api"; end

    KEYS_MAP = {
      id:               :id,
      name:             :name,
      mac_address:      :mac,
      api_version:      :apiversion,
      software_version: :swversion,

      ip:               :ipaddress,
    }

    class << self
      include Discovery::SSDP
      include Discovery::NUPnP

      def agent; @agent ||= HTTP.new; end

      # Find all bridges.
      #
      # * If `ip` is specified, or `HUE_BRIDGE_IP` is set, a `Bridge` will be
      #   returned for that IP, and generally discovery will be skipped.
      # * If `force_discovery` is set, then discovery will be performed *in
      #   addition to* using the explicit IP.
      def all(ip: nil, force_discovery: false)
        @all ||= begin
          eff_ip        = determine_effective_ip(ip)

          bridges       = []
          bridges      += [Bridge.new(agent, "ipaddress" => eff_ip)] if eff_ip
          # TODO: Perhaps, given the use-case it supports, we want to do ALL
          # TODO: discovery searches when `force_discovery` is present?
          bridges      += find_by_discovery if !eff_ip || force_discovery

          filter_bridges(bridges)
        end
      end

      def find_by_discovery
        bridges = find_by_ssdp
        bridges = find_by_nupnp unless bridges.length > 0

        filter_bridges(bridges)
      end

      def find_by_ssdp
        return [] if ENV["HUE_SKIP_SSDP"] && ENV["HUE_SKIP_SSDP"] != ""
        puts "INFO: Discovering bridges via SSDP..."

        bridges = ssdp_scan!.map { |resp| Bridge.new(agent, resp) }

        filter_bridges(bridges)
      end

      def find_by_nupnp
        return [] if ENV["HUE_SKIP_NUPNP"] && ENV["HUE_SKIP_NUPNP"] != ""
        puts "INFO: Discovering bridges via N-UPnP..."

        bridges = nupnp_scan!.map { |resp| Bridge.new(agent, resp) }

        filter_bridges(bridges)
      end

    private

      def determine_effective_ip(explicit_ip)
        ip_var        = ENV["HUE_BRIDGE_IP"]
        have_ip_var   = ip_var && ip_var != ""

        explicit_ip || (have_ip_var ? ip_var : nil)
      end

      def filter_bridges(bridges)
        bridges
          .sort { |a, b| a.ip <=> b.ip }
          .uniq(&:ip)
          .uniq
      end
    end
  end
end
