module FluxHue
  module CLI
    # Helper to cleanse and format data from a Light for display.
    class LightPresenter < Presenter
      def initialize(light); @light = light; end
      def_delegators :@light, :id, :type, :model, :name, :color_mode, :hue,
                     :saturation, :brightness, :color_temperature, :alert,
                     :effect, :software_version

      def on?; from_boolean(@light.on?); end
      def reachable?; from_boolean(@light.reachable?); end

      def x_y
        [@light.x, @light.y].compact.map { |n| "%0.4f" % n }.join(", ")
      end
    end

    # CLI functionality for interacting with lights.
    class Light < Base
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
      def inspect
        rows    = client
                  .lights
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
        hue lights set all on --hue 12345\n
        hue lights set 1 2 3 4 --bri 25\n
        hue lights set all --alert lselect\n
        hue lights set 1 off\n
      LONGDESC
      shared_nameable_light_options
      def set(*ids)
        all_lights  = ids.find { |id| id.downcase == "all" }
        lights      = client
                      .lights
                      .select { |light| all_lights || ids.include?(light.id) }
        fail UnknownLight unless lights.length > 0

        new_name      = options[:name]
        body          = clean_body(options, state: options[:state])

        change_state  = body.length > 0
        change_name   = (new_name && new_name != lights.first.name)
        fail NothingToDo unless change_state || change_name
        fail ParameterNotModifiable if new_name && lights.length > 1

        lights.each do |light|
          puts light.apply_state(body) if change_state
        end
        lights.first.name = new_name if change_name
      end
    end
  end
end
