module FluxHue
  # This module represents functionality common to things that behave like
  # lights.  Specifically, lights and groups of lights.
  module EditableState
    def on?; !!@state["on"]; end
    def on!; self.on = true; end
    def off!; self.on = false; end

    LIGHT_STATE_PROPERTIES = %w(on hue saturation brightness color_temperature
                                alert effect)
    LIGHT_STATE_PROPERTIES.each do |key|
      define_method "#{key}=" do |value|
        apply_state(key.to_s => value)
        instance_variable_set("@#{key}", value)
      end
    end

    attr_reader(*LIGHT_STATE_PROPERTIES)

    def set_xy(x, y)
      apply_state(xy: [x, y])
      @x = x
      @y = y
    end
  end
end
