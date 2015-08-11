module Widget
  # Class to represent a radio-button group control on a Novation Launchpad.
  class RadioGroup < Base
    attr_accessor :on_select, :on_deselect

    def initialize(launchpad:, x:, y:, width:, height:, on:, off:, down:, on_select: nil, on_deselect:, value: nil)
      super(launchpad: launchpad, x: x, y: y, width: width, height: height, on: on, off: off, down: down, value: value)
      @on_select    = on_select
      @on_deselect  = on_deselect
    end

    def render
      (0..max_x).each do |xx|
        (0..max_y).each do |yy|
          col = (value == index_for(x: xx, y: yy)) ? on : off

          change_grid(x: xx, y: yy, color: col)
        end
      end
    end

  protected

    def on_down(x:, y:)
      vv = index_for(x: x, y: y)
      vv = nil if value == vv
      @value = vv
      super(x: x, y: y)

      handler = value ? on_select : on_deselect
      handler.call(value) if handler
    end
  end
end
