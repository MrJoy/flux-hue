module SparkleMotion
  module LaunchPad
    # Base class for Launchpad UI widgets.
    class Widget
      attr_reader :value, :x, :y, :width, :height
      attr_accessor :on, :off, :down

      # TODO: Use `Vector2` for position/size...
      def initialize(launchpad:, x: nil, y: nil, position: nil, width:, height:, on:, off:, down:,
                     value:)
        @x          = x
        @y          = y
        @position   = position
        @width      = width
        @height     = height
        @launchpad  = launchpad
        @value      = value
        @pressed    = {}
        set_colors!(on, off, down)
        attach_handler!
      end

      def update(value, render_now = true)
        @value = value
        @value = max_v if max_v && @value && @value > max_v
        render if render_now
      end

      def render
        @pressed.map do |idx, state|
          next unless state
          if @x
            xx, yy = coords_for(idx: idx)
            change_grid(x: xx, y: yy, color: down)
          else
            change_command(position: @position, color: down)
          end
        end
      end

      def blank
        black = SparkleMotion::LaunchPad::Color::BLACK.to_h
        if @x
          (0..max_x).each do |xx|
            (0..max_y).each do |yy|
              change_grid(x: xx, y: yy, color: black)
            end
          end
        else
          change_command(position: @position, color: black)
        end
      end

      def max_v
        if @x
          @max_v ||= (height * width) - 1
        else
          1
        end
      end

    protected

      attr_reader :launchpad

      def tag
        @tag ||= begin
          pos = @x ? "#{@x},#{@y}" : @position
          "#{self.class.name}(#{pos})"
        end
      end

      def pressed!(x: nil, y: nil, position: nil)
        idx = x ? index_for(x: x, y: y) : position
        @pressed[idx] = true
      end

      def released!(x: nil, y: nil, position: nil)
        idx = x ? index_for(x: x, y: y) : position
        @pressed.delete(idx) if @pressed.key?(idx)
      end

      def handle_grid_response(action)
        guard_call(tag) do
          xx  = action[:x] - @x
          yy  = action[:y] - @y
          if action[:state] == :down
            pressed!(x: xx, y: yy)
            on_down(x: xx, y: yy)
          else
            released!(x: xx, y: yy)
            on_up(x: xx, y: yy)
          end
        end
      end

      def handle_command_response(action)
        guard_call(tag) do
          if action[:state] == :down
            pressed!(position: @position)
            on_down(position: @position)
          else
            released!(position: @position)
            on_up(position: @position)
          end
        end
      end

      def index_for(x:, y:); (y * width) + x; end
      def coords_for(idx:); [idx / width, idx % width]; end

      # Defaults that you may want to override:
      def on_down(x: nil, y: nil, position: nil)
        if @x
          change_grid(x: x, y: y, color: down)
        else
          change_command(position: position, color: down)
        end
      end

      # rubocop:disable Lint/UnusedMethodArgument
      def on_up(x: nil, y: nil, position: nil); render; end
      # rubocop:enable Lint/UnusedMethodArgument

      # Internal utilities for you to use:
      def change_grid(x:, y:, color:)
        return if (x > max_x) || (x < 0)
        return if (y > max_y) || (y < 0)
        col = effective_color(x: x, y: y, color: color)
        grid_apply_color(x, y, col)
      end

      def effective_color(x:, y:, color:)
        color.is_a?(Array) ? color[index_for(x: x, y: y)] : color
      end

      def change_command(position:, color:)
        return unless launchpad
        launchpad.device.change_command(position, color[:r], color[:g], color[:b])
      end

      def grid_apply_color(x, y, color)
        return unless launchpad
        launchpad.device.change_grid(x + @x, y + @y, color[:r], color[:g], color[:b])
      end

      def max_y; @max_y ||= height - 1; end
      def max_x; @max_x ||= width - 1; end

    private

      def set_colors!(on, off, down)
        @on   = normalize_color!(on)
        @off  = normalize_color!(off)
        @down = normalize_color!(down)
      end

      def normalize_color!(color)
        black = SparkleMotion::LaunchPad::Color::BLACK.to_h
        color.is_a?(Array) ? color.map { |oo| black.merge(oo) } : black.merge(color)
      end

      def attach_handler!
        attach_grid_handler!
        attach_position_handler!
      end

      def attach_grid_handler!
        return unless @x
        return unless launchpad
        xx = @x..(@x + max_x)
        yy = @y..(@y + max_y)
        launchpad.response_to(:grid, :both, x: xx, y: yy) do |_inter, action|
          handle_grid_response(action)
        end
      end

      def attach_position_handler!
        return if @x
        return unless launchpad
        launchpad.response_to(@position, :both) do |_inter, action|
          handle_command_response(action)
        end
      end
    end
  end
end
