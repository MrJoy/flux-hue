module FluxHue
  module CLI
    # Helper to cleanse and format data from a Light for display.
    class LightPresenter < Presenter
      def_delegators :@entity, :id, :type, :model, :name, :color_mode, :hue,
                     :saturation, :brightness, :color_temperature, :alert,
                     :effect, :software_version

      boolean :on?, :reachable?

      def x_y
        [@entity.x, @entity.y].compact.map { |n| "%0.4f" % n }.join(", ")
      end
    end

    # CLI functionality for interacting with lights.
    class Lights < Base
      LIGHT_FIELDS = {
        id:                 "ID",
        type:               "Type",
        model:              "Model",
        name:               "Name",
        on?:                "On?",
        color_mode:         "Mode",
        hue:                "Hue",
        saturation:         "Saturation",
        brightness:         "Brightness",
        x_y:                "X/Y",
        color_temperature:  "Temp",
        alert:              "Alert",
        effect:             "Effect",
        software_version:   "Software Version",
        reachable?:         "Reachable?",
      }

      desc "inspect [--order=X,Y,...]",
           "Find information about all of the lights on your network"
      shared_access_controlled_options
      method_option :sort, type: :string, aliases: "--order"
      method_option :unreachable, type: :boolean
      method_option :reachable, type: :boolean
      def inspect
        lights  = apply_light_filters(client.lights, options)

        rows    = lights
                  .map { |light| LightPresenter.new(light) }
                  .map { |light| extract_fields(light, LIGHT_FIELDS) }

        puts render_table(apply_sorting(rows), LIGHT_FIELDS)
      end

      desc "add", "Search for new lights"
      shared_access_controlled_options
      def add
        puts client.add_lights.inspect
      end

      desc "set <all|id ...> [shared options] [light options]",
           "Manipulate a light, or all lights, on your network"
      long_desc <<-LONGDESC
      Examples:\n
        hue lights set all --state on --hue 12345\n
        hue lights set 1 2 3 4 --bri 25\n
        hue lights set all --alert lselect\n
        hue lights set 1 --state off\n
      LONGDESC
      shared_nameable_light_options
      def set(*ids)
        lights            = selected_lights!(ids)

        body, name        = extract_changes(options)
        ch_st, ch_na      = detect_changes!(lights, body, name)

        lights.each { |light| puts light.apply_state(body) } if ch_st
        lights.first.name = name if ch_na
      end

    private

      def apply_light_filters(lights, options)
        lights  = lights.select(&:reachable?) if options[:reachable]
        lights  = lights.reject(&:reachable?) if options[:unreachable]
        lights
      end

      def detect_changes!(lights, body, name)
        change_state  = body.length > 0
        change_name   = (name && name != lights.first.name)
        fail ParameterNotModifiable if name && lights.length > 1
        fail NothingToDo unless change_state || change_name

        [change_state, change_name]
      end

      def extract_changes(opts); [clean_body(opts), opts[:name]]; end

      def selected_lights!(ids)
        # TODO: More proper determination of what is/isn't valid for light IDs!
        use_all = ids.find { |id| id.downcase == "all" }
        ids     = unique_light_ids(ids)
        lights  = client.lights
        lights  = lights.select { |ll| ids.include?(ll.id) } unless use_all
        lights  = lights.select(&:reachable?)
        fail UnknownLight unless use_all || lights.length == ids.length
        lights
      end

      def unique_light_ids(ids); ids.map(&:to_i).sort.uniq; end
    end
  end
end
