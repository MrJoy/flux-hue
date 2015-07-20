module FluxHue
  # Models an individual lightbulb in the Hue system, providing means of
  # both reading and updating the state/configuration of the bulb.
  class Light
    include TranslateKeys
    include EditableState

    HUE_RANGE               = 0..65_535
    # TODO: Bridge is clamping us to 254 on these.  Enforce that here?
    SATURATION_RANGE        = 0..255
    BRIGHTNESS_RANGE        = 0..255
    # TODO: Is the color temp range fixed, or does it depend on the light?  The
    # TODO: lights have different white-points!
    COLOR_TEMPERATURE_RANGE = 153..500

    # Client the light is associated with.
    attr_reader :client

    # Various properties provided to us by the bridge.
    attr_reader :id, :name, :x, :y, :color_mode, :type, :model,
                :software_version

    def initialize(client:, id:, data: {}, state: {})
      @client = client
      @id     = id
      @state  = state
      unpack(data)
    end

    def name=(new_name)
      response  = agent.put(url, "name" => new_name)
      response  = response.first if response.is_a?(Array)
      error     = response["error"]

      fail FluxHue.get_error(error) if error

      # TODO: actual error handling?
      return unless response["success"]

      @name = new_name
    end

    # Indicates if a light can be reached by the bridge.
    def reachable?; @state["reachable"]; end

    # @param transition The duration of the transition from the light's current
    #   state to the new state. This is given as a multiple of 100ms and
    #   defaults to 4 (400ms). For example, setting transistiontime:10 will
    #   make the transition last 1 second.
    def apply_state(attributes, transition = nil)
      body                    = translate_keys(attributes, STATE_KEYS_MAP)
      body["transitiontime"]  = (transition * 10.0).to_i if transition

      agent.put("#{url}/state", body)
    end

    # Refresh the state of the light.
    def refresh!
      unpack(agent.get(url))
      self
    end

  private

    def agent; client.agent; end

    KEYS_MAP = {
      state:            :state,
      type:             :type,
      name:             :name,
      model:            :modelid,
      software_version: :swversion,
      point_symbol:     :pointsymbol,
    }

    STATE_KEYS_MAP = {
      on:                 :on,
      brightness:         :bri,
      hue:                :hue,
      saturation:         :sat,
      xy:                 :xy,
      color_temperature:  :ct,
      alert:              :alert,
      effect:             :effect,
      color_mode:         :colormode,
      reachable:          :reachable,
    }

    def unpack(hash)
      unpack_hash(hash, KEYS_MAP)
      unpack_hash(@state, STATE_KEYS_MAP)
      @id     = @id.to_i if @id
      @x, @y  = @state["xy"]
    end

    def collection_url; "#{client.url}/lights"; end
    def url; "#{collection_url}/#{id}"; end
  end
end
