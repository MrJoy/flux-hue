require 'terminal-table'

module Hue
  class Cli < CliBase
    desc 'lights', 'Find all of the lights on your network'
    shared_options
    def lights
      headings = ["ID", "Name", "Status", "Hue", "Saturation", "Brightness"]
      rows = client(options).lights.each_with_object([]) do |light, r|
        status = light.off? ? "OFF" : "ON"
        r << [light.id, light.name, status, light.hue, light.saturation, light.brightness]
      end
      puts Terminal::Table.new(rows: rows, headings: headings)
    end

    desc 'add', 'Search for new lights'
    shared_options
    def add
      client(options).add_lights
    end

    desc 'all [STATE] [COLOR]', 'Send commands to all lights'
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

    desc 'light ID [STATE] [COLOR]', 'Access a light'
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
      client(options).groups.each do |group|
        puts group.id.to_s.ljust(6) + group.name
        group.lights.each do |light|
          puts " -> " + light.id.to_s.ljust(6) + light.name
        end
      end
    end

    desc 'group [ID] [STATE] [COLOR] [NAME] [LIGHTS]', 'Update a group of lights'
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

    desc 'name ID NAME', 'Update the name of a light'
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
      hue create_group "My Group" --lights "1, 2, 3, 4"
    LONGDESC
    shared_options
    method_option :lights, :type => :string
    def create_group(name)
      # TODO: Ensure name doesn't collide.
      all_options   = options.dup
      client_ref    = client(options)
      group         = client_ref.group

      group.name    = name
      group.lights  = lights_from(all_options)
      result        = group.create!

      if result.is_a?(Fixnum)
        puts "ID: #{result}"
      else
        puts "ERROR: #{result.inspect}"
      end
    end

    desc 'destroy_group ID', 'Destroy a group'
    long_desc <<-LONGDESC
    Examples: \n
      hue destroy_group 1
    LONGDESC
    shared_options
    def destroy_group(id)
      all_options   = options.dup
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
