module Hue
  class Cli < CliBase
    desc 'lights', 'Find all of the lights on your network'
    shared_options
    def lights
      client(options[:user]).lights.each do |light|
        puts light.id.to_s.ljust(6) + light.name
      end
    end

    desc 'add', 'Search for new lights'
    shared_options
    def add
      client(options[:user]).add_lights
    end

    desc 'all STATE [COLOR]', 'Send commands to all lights'
    shared_options
    shared_light_options
    long_desc <<-LONGDESC
    Examples: \n
      hue all on --hue 12345\n
      hue all --bri 25\n
      hue all --alert lselect\n
      hue all off\n
    LONGDESC
    def all(state = 'on')
      body = clean_body(options, state: state)
      client(options[:user]).lights.each do |light|
        puts light.set_state body
      end
    end

    desc 'light ID STATE [COLOR]', 'Access a light'
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
      light = client(options[:user]).light(id)
      puts light.name

      body = clean_body(options, state: state)
      puts light.set_state(body) if body.length > 0
    end

    desc 'groups', 'Find all light groups on your network'
    shared_options
    def groups
      client(options[:user]).groups.each do |group|
        puts group.id.to_s.ljust(6) + group.name
        group.lights.each do |light|
          puts " -> " + light.id.to_s.ljust(6) + light.name
        end
      end
    end

    desc 'group ID STATE [COLOR]', 'Update a group of lights'
    long_desc <<-LONGDESC
    Examples: \n
      hue groups 1 on --hue 12345
      hue groups 1 --bri 25
      hue groups 1 --alert lselect
      hue groups 1 off
    LONGDESC
    shared_options
    shared_light_options
    def group(id, state = nil)
      group = client(options[:user]).group(id)
      puts group.name

      body = clean_body(options, state: state)
      puts group.set_state(body) if body.length > 0
    end

  private

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

    def client(username = Hue::USERNAME)
      @client ||= Hue::Client.new username
    end
  end
end
