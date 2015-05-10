module Hue
  class Cli < CliBase
    desc 'lights', 'Find all of the lights on your network'
    shared_options
    def lights
      client(options[:user]).lights.each do |light|
        puts light.id.to_s.ljust(6) + light.name
      end
    end

    desc 'add LIGHTS', 'Search for new lights'
    shared_options
    def add(thing)
      case thing
      when 'lights'
        client(options[:user]).add_lights
      end
    end

    desc 'all STATE [COLOR]', 'Send commands to all lights'
    shared_options
    method_option :hue, :type => :numeric
    method_option :sat, :type => :numeric, :aliases => '--saturation'
    method_option :bri, :type => :numeric, :aliases => '--brightness'
    method_option :alert, :type => :string
    long_desc <<-LONGDESC
    Examples: \n
      hue all on --hue 12345\n
      hue all --bri 25\n
      hue all --alert lselect\n
      hue all off\n
    LONGDESC
    def all(state = 'on')
      body = options.dup
      body[:on] = state == 'on'
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
    method_option :hue, :type => :numeric
    method_option :sat, :type => :numeric, :aliases => '--saturation'
    method_option :bri, :type => :numeric, :aliases => '--brightness'
    method_option :alert, :type => :string
    method_option :effect, :type => :string
    method_option :transitiontime, :type => :numeric
    def light(id, state = nil)
      light = client(options[:user]).light(id)
      puts light.name

      body = options.dup
      # We no longer need :user so remove it.
      body.delete(:user)
      body[:on] = (state == 'on' || !(state == 'off'))
      puts light.set_state(body) if body.length > 0
    end

    desc 'groups', 'Find all light groups on your network'
    def groups
      client.groups.each do |group|
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
    method_option :hue, :type => :numeric
    method_option :sat, :type => :numeric, :aliases => '--saturation'
    method_option :bri, :type => :numeric, :aliases => '--brightness'
    method_option :alert, :type => :string
    def group(id, state = nil)
      group = client.group(id)
      puts group.name

      body = options.dup
      body[:on] = (state == 'on' || !(state == 'off'))
      puts group.set_state(body) if body.length > 0
    end

  private

    def client(username = Hue::USERNAME)
      @client ||= Hue::Client.new username
    end
  end
end
