module SparkleMotion
  module Widgets
    attr_reader :screens
    class TabSet
      def initialize(name, screen_set, controller, colors, on_change: nil, &handler)
        @name       = name
        @screen_set = screen_set
        @controller = controller
        @tabs       = []
        @colors     = colors
        @screens    = []
        @on_change  = on_change
        instance_eval(&handler)
      end

      def enable
        @tabs.each(&:enable)
        update(@active) if @active
      end

      def disable
        @tabs.each(&:disable)
      end

      def tab(position, screen = nil, &handler)
        idx           = @tabs.length
        @screens[idx] = screen if screen
        @tabs[idx]    = SparkleMotion::LaunchPad::Widgets::Toggle
                        .new(launchpad:  @controller,
                             position:   position.to_sym,
                             colors:     @colors,
                             on_press:   proc do |val|
                               if val == 0 && idx == @active
                                 # Don't allow de-selection!
                                 @tabs[idx].update(true)
                               else
                                 update(idx)
                                 @screens.each do |sc|
                                   if sc != screen
                                     sc.stop
                                   end
                                 end
                                 screen.start
                                 handler.call(idx, val) if handler
                               end
                             end)
      end

      def screens; @screen_set.screens; end

      def update(val)
        @screen_set.state[@name] = @active = val
        @tabs.each_with_index do |tab, i|
          tab.update(i == @active)
        end
        @on_change.call(val) if @on_change
      end
    end
  end
end
