require 'terminal-table'

# TODO: Normalize output, error handling, etc.

# TODO: Failure handling for setting names/lights.
module Hue
  # TODO: `Cli` is an acronym, treat it as such.
  class Cli < CliBase
    BRIDGES_FIELDS = {
      "ID"                => :id,
      "Name"              => :name,
      "IP"                => :ip,
      "MAC"               => :mac_address,
      "API Version"       => :api_version,
      "Software Version"  => :software_version,
    }

    desc 'bridges', 'Find all the bridges on your network'
    shared_bridge_options
    def bridges
      # TODO: Extended output form that includes proxy_address, proxy_port,
      # TODO: known_clients, network_mask, gateway, dhcp, etc...
      bridges = Bridge.all(ip: options[:ip], force_discovery: true)
      rows    = bridges.each_with_object([]) do |br, r|
        # TODO: Make this happen on-demand when accessing a property that isn't
        # TODO: populated yet.
        br.refresh!
        r << BRIDGES_FIELDS.values.map { |prop| br.send(prop) }
      end
      puts Terminal::Table.new(rows: rows, headings: BRIDGES_FIELDS.keys)
    end

    # TODO: Coalesce proxy_address and proxy_port, but filter magic `none`
    # TODO: value...
    BRIDGE_FIELDS = {
      "ID"                    => :id,
      "IP"                    => :ip,
      "MAC"                   => :mac_address,

      "Name"                  => :name,
      "Channel"               => :zigbee_channel,
      "Net Mask"              => :network_mask,
      "Gateway"               => :gateway,
      "DHCP?"                 => :dhcp,
      "Proxy Address"         => :proxy_address,
      "Proxy Port"            => :proxy_port,

      "Portal Services?"      => :portal_services?,
      "Connected to Portal?"  => :portal_connection,
      "Portal State"          => :portal_state,

      "API Version"           => :api_version,
      "Software Version"      => :software_version,
      "Update Info"           => :software_update_summary,

      "Button?"               => :link_button?,
    }

    desc 'bridge <id> [--ip=<bridge IP>]', 'Show information about a particular bridge on your network.'
    long_desc <<-LONGDESC
      If <id> is '-', then the first discovered bridge will be used.  This is
        most useful in conjunction with --ip or HUE_BRIDGE_IP.\n
      Examples:\n
        hue bridge 0017881226f3\n
        hue bridge -\n
    LONGDESC
    shared_bridge_options
    def bridge(id)
      cleansed_id = id.upcase
      # TODO: Command to get known_clients, etc...
      bridges = Bridge.all(ip: options[:ip])
      if id == '-'
        chosen_bridge = bridges.first
      else
        # TODO: Make Bridge cleanse ID!
        chosen_bridge = bridges.find { |br| br.id.upcase == cleansed_id }
      end

      raise UnknownBridge unless chosen_bridge

      # TODO: Make this happen on-demand when accessing a property that isn't
      # TODO: populated yet, or after setting the client!
      client.refresh!
      rows = [BRIDGE_FIELDS.values.map { |prop| client.send(prop) }]

      puts Terminal::Table.new(rows: rows, headings: BRIDGE_FIELDS.keys)
    end


    LIGHT_FIELDS = [
      "ID",
      "Type",
      "Model",
      "Name",
      "Status",
      "Mode",
      "Hue",
      "Saturation",
      "Brightness",
      "X/Y",
      "Temp",
      "Alert",
      "Effect",
      "Software Version",
      "Reachable?",
    ]

    desc 'lights [--order=X,Y,...]', 'Find all of the lights on your network'
    shared_access_controlled_options
    method_option :sort, :type => :string, :aliases => '--order'
    def lights
      rows = client.lights.each_with_object([]) do |light, r|
        r << [
          light.id,
          light.type,
          light.model,
          light.name,
          (light.off? ? "Off" : "On"),
          light.color_mode,
          light.hue,
          light.saturation,
          light.brightness,
          [light.x, light.y].compact.map { |n| "%0.4f" % n }.join(", "),
          light.color_temperature,
          light.alert,
          light.effect,
          light.software_version,
          (light.reachable? ? "Yes" : "No"),
        ]
      end
      if options[:sort]
        sorting = parse_list(options[:sort])
        rows.sort! do |a, b|
          sorting
            .map { |k| a[k] <=> b[k] }
            .find { |n| n != 0 } || 0
        end
      end
      puts Terminal::Table.new(rows: rows, headings: LIGHT_FIELDS)
    end

    desc 'add', 'Search for new lights'
    shared_access_controlled_options
    def add
      client.add_lights
    end

    desc 'all [shared options] [light options]', 'Manipulate all lights'
    shared_light_options
    long_desc <<-LONGDESC
    Examples:\n
      hue all on --hue 12345\n
      hue all --bri 25\n
      hue all --alert lselect\n
      hue all off\n
    LONGDESC
    def all(state = nil)
      body          = clean_body(options, state: state)

      change_state  = body.length > 0
      raise NothingToDo unless change_state

      client.lights.each do |light|
        puts light.set_state(body)
      end
    end

    desc 'light <id> [shared options] [light options]', 'Manipulate a light'
    long_desc <<-LONGDESC
    Examples:\n
      hue light 1 on --hue 12345 \n
      hue light 1 --brightness 25\n
      hue light 1 --alert lselect\n
      hue light 1 off\n
    LONGDESC
    shared_nameable_light_options
    def light(id, state = nil)
      light         = client.light(id)
      raise UnknownLight unless light

      new_name      = options[:name]
      body          = clean_body(options, state: state)

      change_state  = body.length > 0
      change_name   = (new_name && new_name != light.name)
      raise NothingToDo unless change_state || change_name

      puts light.set_state(body) if change_state
      light.name = new_name if change_name
    end

    GROUP_FIELDS = ["ID", "Name", "Light IDs", "Lights"]

    desc 'groups', 'Find all light groups on your network'
    shared_access_controlled_options
    def groups
      rows    = client.groups.each_with_object([]) do |group, r|
        lights  = group
                  .lights
                  .sort { |a, b| a.id.to_i <=> b.id.to_i }
        r << [
          group.id,
          group.name,
          lights.map(&:id).join("\n"),
          lights.map(&:name).join("\n"),
        ]
      end
      puts Terminal::Table.new(rows: rows, headings: GROUP_FIELDS)
    end

    desc 'group <id> [shared options] [light options]', 'Manipulate a group of lights'
    long_desc <<-LONGDESC
    Examples:\n
      hue group 1 on --hue 12345\n
      hue group 1 --bri 25\n
      hue group 1 --name "My Group"\n
      hue group 1 --alert lselect\n
      hue group 1 --lights "1, 2, 3"\n
      hue group 1 off\n
    LONGDESC
    shared_nameable_light_options
    method_option :lights, :type => :string
    def group(id, state = nil)
      group         = client.group(id)
      lights        = group
                      .lights
                      .map(&:id)
                      .map(&:to_i)
                      .sort

      new_name      = options[:name]
      new_lights    = parse_lights(options[:lights])
      body          = clean_body(options, state: state)

      change_state  = body.length > 0
      change_name   = (new_name && new_name != group.name)
      change_lights = (lights && new_lights != lights)
      raise NothingToDo unless change_state || change_name || change_lights

      puts group.set_state(body) if change_state
      group.name    = new_name if change_name
      group.lights  = lights if change_lights
    end

    desc 'create_group <name> <id> [<id>...]', 'Create a new group'
    long_desc <<-LONGDESC
    Examples:\n
      hue create_group "My Group" 1 2 3 4\n
    LONGDESC
    shared_access_controlled_options
    def create_group(name, *lights)
      # TODO: Make `create!` be a static method, and add an errors accessor!

      # TODO: Ensure name doesn't collide?

      # TODO: Warn if the name is a poor choice for symbolic usage?
      group         = Group.new(client,
                                name:   name,
                                lights: Array(lights)
                                        .map(&:strip)
                                        .map(&:to_i)
                                        .sort)

      result        = group.create!

      raise InvalidUsage, result.inspect unless result.is_a?(Fixnum)

      puts "SUCCESS: Created group ##{result}"
    end

    desc 'destroy_group <id>', 'Destroy a group'
    long_desc <<-LONGDESC
    Examples:\n
      hue destroy_group 1\n
    LONGDESC
    shared_access_controlled_options
    def destroy_group(id)
      group   = client.group(id)
      raise UnknownGroup unless group

      result  = group.destroy!

      raise InvalidUsage, result.inspect unless result === true

      puts "SUCCESS: Destroyed group ##{id}."
    end

  private

    def parse_list(raw)
      (raw || "")
        .strip
        .split(/[,\s]+/)
        .map(&:to_i)
    end

    def parse_lights(raw)
      parse_list(raw)
        .sort
        .uniq
        .reject { |n| n == 0 }
    end

    # TODO: Turn this into a whitelist instead of a blacklist.
    NON_API_REQUEST_KEYS=%i(user ip lights name)

    def clean_body(options, state: nil)
      body = options.dup
      # Remove keys that are for signalling our code and are unknown to the
      # bridge.
      NON_API_REQUEST_KEYS.each do |key|
        body.delete(key)
      end
      body[:on] = (state == 'on' || state != 'off') if state
      body
    end

    def bridge
      @bridge ||= begin
        tmp = Bridge.all(ip: options[:ip]).first
        raise UnknownBridge unless tmp
        tmp
      end
    end

    def client
      @client ||= Hue::Client.new(bridge, username: options[:user])
    end
  end
end
