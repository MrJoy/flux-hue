module SparkleMotion
  module Widgets
    # A collection of widgets that can be enabled/disabled together.
    class Screen
      include SparkleMotion::Hue::HTTP
      attr_accessor :widgets, :state

      def initialize(screen_set, controller, state, logger)
        @screen_set = screen_set
        @state      = state
        @controller = controller
        @logger     = logger
        @widgets    = {}
        @defaults   = {}
        @started    = false
      end

      def start
        return if @started
        @started = true
        # TODO: Want to gate this...
        @widgets.each do |name, widget|
          widget.enable
          next unless @defaults.key?(name)
          widget.update(@defaults[name])
        end
      end

      def stop
        return unless @started
        @started = false
        @widgets.values.each(&:disable)
      end

      def draw(&callback)
        instance_eval(&callback)
        self
      end

      def vertical_slider(name, position, size, colors:, default: 0, &handler)
        widget = SparkleMotion::LaunchPad::Widgets::VerticalSlider
                 .new(launchpad:   @controller,
                      position:    SparkleMotion::Vector2.new(position),
                      size:        size,
                      colors:      colors,
                      on_change:   proc do |val|
                        state[name] = val
                        handler.call(val) if handler
                      end)
        state.parameter!(name, default) do |_key, value|
          widget.update(value)
        end
        @widgets[name] = widget
      end

      def radio_group(name, position, size, colors:, default: 0, allow_off: true, &handler)
        widget = SparkleMotion::LaunchPad::Widgets::RadioGroup
                 .new(launchpad:   @controller,
                      position:    SparkleMotion::Vector2.new(position),
                      size:        SparkleMotion::Vector2.new(size),
                      colors:      colors,
                      on_select:   proc do |val|
                        state[name] = val
                        handler.call(val) if handler
                      end,
                      on_deselect: proc do |val|
                        if allow_off
                          state[name] = nil
                          handler.call(nil) if handler
                        else
                          update(val) if handler
                        end
                      end)
        state.parameter!(name, default) do |_key, value|
          widget.update(value)
        end
        @widgets[name] = widget
      end

      def button(name, position, colors:, &handler)
        widget =  SparkleMotion::LaunchPad::Widgets::Button
                  .new(launchpad:  @controller,
                       position:   position.to_sym,
                       colors:     colors,
                       on_press:   handler)
        @defaults[name] = false
        @widgets[name]  = widget
      end

      def toggle(name, position, default: false, colors:, &handler)
        widget =  SparkleMotion::LaunchPad::Widgets::Toggle
                  .new(launchpad:  @controller,
                       position:   position.to_sym,
                       colors:     colors,
                       on_press:   handler)
        state.parameter!(name, default) do |_key, value|
          widgets.update(value)
        end
        @widgets[name] = widget
      end

      def tab_set(name, colors:, default:, &handler)
        @widgets[name] = TabSet.new(@screen_set, @controller, colors, default, &handler)
      end
    end
  end
end
