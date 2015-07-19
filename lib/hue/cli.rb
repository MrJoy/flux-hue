require 'terminal-table'

module Hue
  class Cli < CliBase
    desc 'bridges', 'Find all the bridges on your network'
    def bridges
      # TODO: Extended output form that includes proxy_address, proxy_port,
      # TODO: known_clients, network_mask, gateway, dhcp, etc...
      headings = ["ID", "Name", "IP", "MAC", "Channel", "API Version", "Software Version", "Update Info"]
      rows = client(options).bridges.each_with_object([]) do |bridge, r|
        bridge.refresh
        r << [
          bridge.id,
          bridge.name,
          bridge.ip,
          bridge.mac_address,
          bridge.zigbee_channel,
          bridge.api_version,
          bridge.software_version,
          (bridge.software_update["text"] rescue nil)
        ]
      end
      puts Terminal::Table.new(rows: rows, headings: headings)
    end

    desc 'lights', 'Find all of the lights on your network'
    shared_options
    method_option :sort, :type => :string, :aliases => '--order'
    def lights
      headings = [
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
      rows = client(options).lights.each_with_object([]) do |light, r|
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
          [light.x, light.y].compact.join(", "),
          light.color_temperature,
          light.alert,
          light.effect,
          light.software_version,
          (light.reachable? ? "Yes" : "No"),
        ]
      end
      if options[:sort]
        sorting = options[:sort].strip.split(/\s*,\s*/).map(&:to_i)
        rows.sort! do |a, b|
          sorting
            .map { |k| a[k] <=> b[k] }
            .find { |n| n != 0 } || 0
        end
      end
      puts Terminal::Table.new(rows: rows, headings: headings)
    end

    desc 'add', 'Search for new lights'
    shared_options
    def add
      client(options).add_lights
    end

    desc 'all [on|off] [--hue=X] [--brightness=X] [--saturation=X]', 'Send commands to all lights'
    shared_options
    shared_light_options
    long_desc <<-LONGDESC
    Examples: \n
      hue all on --hue 12345\n
      hue all --bri 25\n
      hue all --alert lselect\n
      hue all off\n
    LONGDESC
    def all(state = nil)
      body = clean_body(options, state: state)
      client(options).lights.each do |light|
        puts light.name
        puts light.set_state body
      end
    end

    desc 'light <id> [on|off] [--hue=X] [--brightness=X] [--saturation=X]', 'Access or update a light'
    long_desc <<-LONGDESC
    Examples: \n
      hue light 1 on --hue 12345  \n
      hue light 1 --bri 25 \n
      hue light 1 --alert lselect \n
      hue light 1 off
    LONGDESC
    shared_options
    shared_light_options
    def light(id, state = nil)
      light = client(options).light(id)
      puts light.name

      body = clean_body(options, state: state)
      puts light.set_state(body) if body.length > 0
    end

    desc 'groups', 'Find all light groups on your network'
    shared_options
    def groups
      headings = ["ID", "Name", "Light IDs", "Lights"]
      rows = client(options).groups.each_with_object([]) do |group, r|
        r << [
          group.id,
          group.name,
          group.lights.map { |light| light.id.to_i }.sort.join(", "),
          group.lights.map { |light| light.name }.sort.join("\n"),
        ]
      end
      puts Terminal::Table.new(rows: rows, headings: headings)
    end

    desc 'group <id> [on|off] [--hue=X] [--brightness=X] [--saturation=X] [--name=X] [--lights=X,Y,Z...]', 'Update a group of lights'
    long_desc <<-LONGDESC
    Examples: \n
      hue group 1 on --hue 12345
      hue group 1 --bri 25
      hue group 1 --name "My Group"
      hue group 1 --alert lselect
      hue group 1 --lights "1, 2, 3"
      hue group 1 off
    LONGDESC
    shared_options
    shared_light_options
    method_option :name, :type => :string
    method_option :lights, :type => :string
    def group(id, state = nil)
      all_options = options.dup
      client_ref  = client(options)
      new_name    = all_options.delete(:name)
      group       = client_ref.group(id)

      if new_name && new_name != group.name
        puts "#{group.name} => #{new_name}"
        group.name = new_name
      else
        puts group.name
      end

      lights = lights_from(all_options)
      cur_lights = group.lights.map(&:id).map(&:to_i).sort
      if lights && lights != cur_lights
        puts "  -> #{lights.join(', ')}"
        group.lights = lights
      end

      body = clean_body(all_options, state: state)
      puts group.set_state(body) if body.length > 0
    end

    desc 'name <id> <name>', 'Update the name of a light'
    long_desc <<-LONGDESC
    Examples: \n
      hue name 1 "My Light"
    LONGDESC
    shared_options
    def name(id, name)
      light = client(options).light(id)
      puts "#{light.name} => #{name}"

      light.name = name if name != light.name
    end

    desc 'create_group NAME [LIGHTS]', 'Create a new group'
    long_desc <<-LONGDESC
    Examples: \n
      hue create_group "My Group" 1 2 3 4
    LONGDESC
    shared_options
    def create_group(name, *lights)
      # TODO: Ensure name doesn't collide.
      client_ref    = client(options)
      group         = client_ref.group

      group.name    = name
      group.lights  = Array(lights).map { |light| light.strip.to_i }.sort
      result        = group.create!

      if result.is_a?(Fixnum)
        puts "ID: #{result}"
      else
        puts "ERROR: #{result.inspect}"
      end
    end

    desc 'destroy_group <id>', 'Destroy a group'
    long_desc <<-LONGDESC
    Examples: \n
      hue destroy_group 1
    LONGDESC
    shared_options
    def destroy_group(id)
      client_ref    = client(options)
      group         = client_ref.group(id)
      if !group
        puts "ERROR: No such group as ##{id}."
        return
      end

      result        = group.destroy!

      if result === true
        puts "Destroyed group ##{id}."
      else
        puts "ERROR: #{result.inspect}"
      end
    end

  private

    def lights_from(all_options)
      lights = all_options.delete(:lights)
      # TODO: Support symbolic names of lights as well!
      lights = lights.strip.split(/\s*,\s*/).map(&:to_i).sort if lights
      lights
    end

    def clean_body(options, state: nil)
      body = options.dup
      # We don't need :user for the request, just for getting a client object
      # so we remove it.
      body.delete(:user)
      # The :ip option is for identifying a hub explicitly, and doesn't belong
      # in the request object.
      body.delete(:ip)
      body[:on] = state_as_bool(state) if state
      body
    end

    def state_as_bool(state)
      (state == 'on' || !(state == 'off'))
    end

    def client(options)
      username  = options[:user] || Hue::USERNAME
      ip        = options[:ip]
      @client ||= Hue::Client.new username, ip
    end
  end
end
