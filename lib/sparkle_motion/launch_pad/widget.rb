module SparkleMotion
  module LaunchPad
    # Base class for Launchpad UI widgets.
    class Widget
      attr_reader :value, :position, :size, :colors

      def initialize(launchpad:, position:, size:, colors:, value:)
        @position   = position
        @size       = size
        @launchpad  = launchpad
        @value      = value
        @pressed    = {}
        @colors     = OpenStruct.new(normalize_colors!(colors))
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
          if on_grid?
            xx, yy = coords_for(idx: idx)
            change_grid(x: xx, y: yy, color: @colors.down)
          else
            change_command(position: @position, color: @colors.down)
          end
        end
      end

      def blank
        black = SparkleMotion::LaunchPad::Color::BLACK.to_h
        if on_grid?
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
        @max_v ||= on_grid? ? (@size.y * @size.x) - 1 : 1
      end

    protected

      attr_reader :launchpad

      def tag
        @tag ||= begin
          pos = on_grid? ? "#{@position.x},#{@position.y}" : @position
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

      def handle_grid_response_down(action)
        xx  = action[:x] - @position.x
        yy  = action[:y] - @position.y
        pressed!(x: xx, y: yy)
        on_down(x: xx, y: yy)
      end

      def handle_grid_response_up(action)
        xx  = action[:x] - @position.x
        yy  = action[:y] - @position.y
        released!(x: xx, y: yy)
        on_up(x: xx, y: yy)
      end

      def handle_command_response_down
        pressed!(position: @position)
        on_down(position: @position)
      end

      def handle_command_response_up
        released!(position: @position)
        on_up(position: @position)
      end

      def index_for(x:, y:); (y * @size.x) + x; end
      def coords_for(idx:); [idx / @size.x, idx % @size.x]; end

      # Defaults that you may want to override:
      def on_down(x: nil, y: nil, position: nil)
        if on_grid?
          change_grid(x: x, y: y, color: @colors.down)
        else
          change_command(position: position, color: @colors.down)
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
        launchpad.device.change(cc: position, red: color[:r], green: color[:g], blue: color[:b])
      end

      def grid_apply_color(x, y, color)
        return unless launchpad
        launchpad.device.change(grid:  [x + position.x, y + position.y],
                                red:   color[:r],
                                green: color[:g],
                                blue:  color[:b])
      end

      def max_y; @max_y ||= @size.y - 1; end
      def max_x; @max_x ||= @size.x - 1; end

      def on_grid?; position.is_a?(Vector2); end

    private

      def normalize_colors!(colors)
        Hash[colors.map { |key, value| [key, normalize_color!(value)] }]
      end

      def normalize_color!(color)
        case color
        when Array  then color.map { |cc| normalize_color!(cc) }
        when Symbol then SparkleMotion::LaunchPad::Color.const_get(color.to_s.upcase).to_h
        when Color  then color.to_h
        else
          SparkleMotion::LaunchPad::Color::BLACK.to_h.merge(color)
        end
      end

      def attach_handler!
        attach_grid_handler!
        attach_position_handler!
      end

      def attach_grid_handler!
        return unless on_grid?
        return unless launchpad
        xx, yy = expand_range
        launchpad.response_to(:grid, :down, x: xx, y: yy) do |_inter, action|
          handle_grid_response_down(action)
        end
        launchpad.response_to(:grid, :up, x: xx, y: yy) do |_inter, action|
          handle_grid_response_up(action)
        end
      end

      def attach_position_handler!
        return if on_grid?
        return unless launchpad
        launchpad.response_to(@position, :down) do |_inter, _action|
          handle_command_response_down
        end
        launchpad.response_to(@position, :up) do |_inter, _action|
          handle_command_response_up
        end
      end

      def expand_range
        [@position.x..(@position.x + max_x),
         @position.y..(@position.y + max_y)]
      end
    end
  end
end
