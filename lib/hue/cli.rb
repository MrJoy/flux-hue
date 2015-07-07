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
      client(options[:user]).lights.each do |light|
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
    def group(id = nil, state = nil)
      all_options = options.dup
      client_ref  = client(options[:user])
      new_name    = all_options.delete(:name)
      if id
        group     = client_ref.group(id)
      else
        puts "Creating new group..."
        group     = Hue::Group
                    .new(client_ref, client.bridge, nil, { name: new_name })
                    .create!
      end
      #initialize(client, bridge, id = nil, data = {})
      if new_name && new_name != group.name
        puts "#{group.name} => #{new_name}"
        group.name = new_name
      else
        puts group.name
      end
      lights = all_options.delete(:lights)
      lights = lights.strip.split(/\s*,\s*/).map(&:to_i).sort if lights

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
      light = client(options[:user]).light(id)
      puts "#{light.name} => #{name}"

      light.name = name if name != light.name
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
