# TODO: Normalize output, error handling, etc.

# TODO: Failure handling for setting names/lights.
require "terminal-table"

module FluxHue
  module CLI
    # CLI interface to library functionality, via Thor.
    class CLI < Base
      register(Bridge, "bridges", "bridges",
               "Discover/inspect/work with bridges")
      register(Light, "lights", "lights",
               "Inspect/work with lights")

      GROUP_FIELDS = ["ID", "Name", "Light IDs", "Lights"]

      desc "groups", "Find all light groups on your network"
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

      desc "group <id> [shared options] [light options]",
           "Manipulate a group of lights"
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
      method_option :lights, type: :string
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
        fail NothingToDo unless change_state || change_name || change_lights

        puts group.apply_state(body) if change_state
        group.name    = new_name if change_name
        group.lights  = lights if change_lights
      end

      desc "create_group <name> <id> [<id>...]", "Create a new group"
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

        fail InvalidUsage, result.inspect unless result.is_a?(Fixnum)

        puts "SUCCESS: Created group ##{result}"
      end

      desc "destroy_group <id>", "Destroy a group"
      long_desc <<-LONGDESC
      Examples:\n
        hue destroy_group 1\n
      LONGDESC
      shared_access_controlled_options
      def destroy_group(id)
        group   = client.group(id)
        fail UnknownGroup unless group

        result  = group.destroy!

        fail InvalidUsage, result.inspect unless result == true

        puts "SUCCESS: Destroyed group ##{id}."
      end

    private

      def parse_lights(raw)
        parse_list(raw)
          .sort
          .uniq
          .reject { |n| n == 0 }
      end

      # TODO: Turn this into a whitelist instead of a blacklist.
      NON_API_REQUEST_KEYS = %i(user ip lights name)

      def clean_body(options, state: nil)
        body = options.dup
        # Remove keys that are for signalling our code and are unknown to the
        # bridge.
        NON_API_REQUEST_KEYS.each do |key|
          body.delete(key)
        end
        body[:on] = (state == "on" || state != "off") if state
        body
      end
    end
  end
end
