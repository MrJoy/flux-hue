module FluxHue
  module CLI
    # Helper to cleanse and format data from a Group for display.
    class GroupPresenter < Presenter
      def_delegators :@entity, :id, :name

      def light_ids; @entity.lights.map(&:id).join("\n"); end
      def light_names; @entity.lights.map(&:name).join("\n"); end
    end

    # CLI functionality for interacting with groups.
    class Groups < Base
      GROUP_FIELDS = {
        id:           "ID",
        name:         "Name",
        light_ids:    "Light IDs",
        light_names:  "Lights",
      }

      desc "inspect", "Find all light groups on your network"
      shared_access_controlled_options
      def inspect
        rows    = client
                  .groups
                  .map { |group| GroupPresenter.new(group) }
                  .map { |group| extract_fields(group, GROUP_FIELDS) }

        puts render_table(rows, GROUP_FIELDS)
      end

      desc "set <id> [shared options] [light options]",
           "Manipulate a group of lights"
      long_desc <<-LONGDESC
      Examples:\n
        hue groups set 1 --state on --hue 12345\n
        hue groups set 1 --bri 25\n
        hue groups set 1 --name "My Group"\n
        hue groups set 1 --alert lselect\n
        hue groups set 1 --lights "1, 2, 3"\n
        hue groups set 1 --state off\n
      LONGDESC
      shared_nameable_light_options
      method_option :lights, type: :string
      def set(id)
        # TODO: Make this work for multiple IDs!
        group               = client.group(id)

        name, lights, body  = extract_changes(options)

        ch_st, ch_na, ch_li = detect_changes!(group, body, name, lights)

        puts group.apply_state(body) if ch_st
        group.name          = name if ch_na
        group.lights        = lights if ch_li
      end

      desc "create <name> <id> [<id>...]", "Create a new group"
      long_desc <<-LONGDESC
      Examples:\n
        hue groups create "My Group" 1 2 3 4\n
      LONGDESC
      shared_access_controlled_options
      def create(name, *lights)
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

      desc "destroy <id>", "Destroy a group"
      shared_access_controlled_options
      def destroy(id)
        group   = client.group(id)
        fail UnknownGroup unless group

        result  = group.destroy!

        fail InvalidUsage, result.inspect unless result == true

        puts "SUCCESS: Destroyed group ##{id}."
      end

    private

      def extract_changes(options)
        [
          options[:name],
          parse_lights(options[:lights]),
          clean_body(options, state: options[:state]),
        ]
      end

      def detect_changes!(group, body, new_name, new_lights)
        lights        = light_ids_from_group(group)
        change_state  = body.length > 0
        change_name   = (new_name && new_name != group.name)
        change_lights = (lights && new_lights != lights)

        fail NothingToDo unless change_state || change_name || change_lights

        [change_state, change_name, change_lights]
      end

      def light_ids_from_group(group)
        group
          .lights
          .map(&:id)
          .map(&:to_i)
          .sort
      end

      def parse_lights(raw)
        parse_list(raw)
          .sort
          .uniq
          .reject { |n| n == 0 }
      end
    end
  end
end
