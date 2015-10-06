module SparkleMotion
  module Widgets
    class TabSet
      def initialize(screen_set, controller, colors, default, &handler)
        @screen_set = screen_set
        @controller = controller
        @tabs       = []
        @active     = default
        @colors     = colors
        @screens    = []
        instance_eval(&handler)
      end

      def enable
        @tabs.each(&:enable)
        update(@active)
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
                                   if sc == screen
                                     sc.start
                                   else
                                     sc.stop
                                   end
                                 end
                                 handler.call(idx, val) if handler
                               end
                             end)
      end

      def screens; @screen_set.screens; end

      def update(val)
        @active = val
        @tabs.each_with_index do |tab, i|
          tab.update(i == @active)
        end
      end
    end
  end
end
