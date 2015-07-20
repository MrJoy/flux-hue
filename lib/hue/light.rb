module Hue
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

    # Unique identification number.
    attr_reader :id

    # Client the light is associated with.
    attr_reader :client

    # A unique, editable name given to the light.
    attr_accessor :name

    # Hue of the light. This is a wrapping value between 0 and 65535.
    # Both 0 and 65535 are red, 25500 is green and 46920 is blue.
    attr_reader :hue

    # Saturation of the light. 255 is the most saturated (colored)
    # and 0 is the least saturated (white).
    attr_reader :saturation

    # Brightness of the light. This is a scale from the minimum
    # brightness the light is capable of, 0, to the maximum capable
    # brightness, 254. (Should be 255 but value clamps to 254!) Note a
    # brightness of 0 is not off.
    attr_reader :brightness

    # The x coordinate of a color in CIE color space. Between 0 and 1.
    #
    # @see http://developers.meethue.com/coreconcepts.html#color_gets_more_complicated
    attr_reader :x

    # The y coordinate of a color in CIE color space. Between 0 and 1.
    #
    # @see http://developers.meethue.com/coreconcepts.html#color_gets_more_complicated
    attr_reader :y

    # The Mired Color temperature of the light. 2012 connected lights
    # are capable of 153 (6500K) to 500 (2000K).
    #
    # @see http://en.wikipedia.org/wiki/Mired
    attr_reader :color_temperature

    # The alert effect, which is a temporary change to the bulb's state.
    # This can take one of the following values:
    # * `none` - The light is not performing an alert effect.
    # * `select` - The light is performing one breathe cycle.
    # * `lselect` - The light is performing breathe cycles for 30 seconds
    #     or until an "alert": "none" command is received.
    #
    # Note that in version 1.0 this contains the last alert sent to the
    # light and not its current state. This will be changed to contain the
    # current state in an upcoming patch.
    #
    # @see http://developers.meethue.com/coreconcepts.html#some_extra_fun_stuff
    attr_reader :alert

    # The dynamic effect of the light, can either be `none` or
    # `colorloop`. If set to colorloop, the light will cycle through
    # all hues using the current brightness and saturation settings.
    attr_reader :effect

    # Indicates the color mode in which the light is working, this is
    # the last command type it received. Values are `hs` for Hue and
    # Saturation, `xy` for XY and `ct` for Color Temperature. This
    # parameter is only present when the light supports at least one
    # of the values.
    attr_reader :color_mode

    # A fixed name describing the type of light.
    attr_reader :type

    # The hardware model of the light.
    attr_reader :model

    # An identifier for the software version running on the light.
    attr_reader :software_version

    # Reserved for future functionality.
    attr_reader :point_symbol

    def initialize(client:, id:, data: {}, state: {})
      @client = client
      @id     = id
      @state  = state
      unpack(data)
    end

    def name=(new_name)
      validate_name!(new_name)

      body      = { name: new_name }

      uri       = URI.parse(url)
      http      = Net::HTTP.new(uri.host)
      response  = JSON(http.request_put(uri.path, JSON.dump(body)).body).first

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
    def set_state(attributes, transition = nil)
      body    = translate_keys(attributes, STATE_KEYS_MAP)

      # Add transition
      body.merge!(transitiontime: (transition * 10.0).to_i) if transition

      uri   = URI.parse("#{url}/state")
      http  = Net::HTTP.new(uri.host)

      JSON(http.request_put(uri.path, JSON.dump(body)).body)
    end

    # Refresh the state of the light.
    def refresh!; unpack(JSON(Net::HTTP.get(URI.parse(base_url)))); end

    # Is the light off?
    def off?; !@state["on"]; end

  private

    NAME_RANGE        = 1..32
    NAME_RANGE_MSG    = "Names must be between #{NAME_RANGE.first} and"\
                          " #{NAME_RANGE.last} characters."

    def validate_name!(username)
      fail InvalidUsername, NAME_RANGE_MSG unless NAME_RANGE
                                                  .include?(username.length)
    end

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
      @x, @y = @state["xy"]
    end

    def collection_url; "#{client.url}/lights"; end
    def url; "#{collection_url}/#{id}"; end
  end
end
