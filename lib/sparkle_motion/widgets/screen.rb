module SparkleMotion
  module Widgets
    # A collection of widgets that can be enabled/disabled together.
    class Screen
      def initialize(screen_set, controller, logger)
        @screen_set = screen_set
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

      def radio_group(name, position, size, colors:, default: 0, allow_off: true, &handler)
        widget =  SparkleMotion::LaunchPad::Widgets::RadioGroup
                  .new(launchpad:   @controller,
                       position:    SparkleMotion::Vector2.new(position),
                       size:        SparkleMotion::Vector2.new(size),
                       colors:      colors,
                       on_select:   proc { |x| handler.call(x) },
                       on_deselect: proc { |x| allow_off ? handler.call(nil) : update(x) })
        @defaults[name] = default
        @widgets[name]  = widget
        widget
      end

      def button(name, position, colors:, &handler)
        widget =  SparkleMotion::LaunchPad::Widgets::Button
                  .new(launchpad:  @controller,
                       position:   position.to_sym,
                       colors:     colors,
                       on_press:   handler)
        @defaults[name] = false
        @widgets[name]  = widget
        widget
      end

      def toggle(name, position, default: false, colors:, &handler)
        widget =  SparkleMotion::LaunchPad::Widgets::Toggle
                  .new(launchpad:  @controller,
                       position:   position.to_sym,
                       colors:     colors,
                       on_press:   handler)
        @defaults[name] = default
        @widgets[name]  = widget
        widget
      end

      def tab_set(name, colors:, default:, &handler)
        @widgets[name] = TabSet.new(@screen_set, @controller, colors, default, &handler)
      end
    end
  end
end
