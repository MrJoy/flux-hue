module FluxHue
  # Models a group of lights in the Hue system, providing means of
  # applying changes to multiple lights at once.
  class Group
    include TranslateKeys
    include EditableState

    # Unique identification number.
    attr_reader :id

    # The Client (and by extension, Bridge) this group is associated with.
    attr_reader :client

    # A unique, editable name given to the group.
    attr_accessor :name

    # Hue of the group. This is a wrapping value between 0 and 65535.
    # Both 0 and 65535 are red, 25500 is green and 46920 is blue.
    attr_accessor :hue

    # Saturation of the group. 255 is the most saturated (colored)
    # and 0 is the least saturated (white).
    attr_accessor :saturation

    # Brightness of the group. This is a scale from the minimum
    # brightness the group is capable of, 0, to the maximum capable
    # brightness, 254. (Should be 255 but value clamps to 254!) Note a
    # brightness of 0 is not off.
    attr_accessor :brightness

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
    attr_accessor :color_temperature

    # A fixed name describing the type of group.
    attr_reader :type

    def initialize(client:, id: nil, name: nil, lights: nil, data: {})
      @client     = client
      @id         = id
      @state      = {}
      @light_ids  = cleanse_lights(lights)
      @name       = name

      unpack(data)
      # TODO: Somewhere upstream we're only getting name when we should be
      # TODO: getting a fair bit more, if possible.  See if we can be
      # TODO: more courteous upstream, and barring that, be more selective
      # TODO: about when to do a refresh here.
      refresh!
    end

    def lights
      @lights ||= begin
        @light_ids.map do |light_id|
          @client.light(light_id)
        end
      end
    end

    def name=(name)
      @name = apply_group_state(name: name)[0]["success"]["/groups/#{id}/name"]
    end

    def lights=(light_ids)
      @light_ids  = cleanse_lights(light_ids)
      @lights     = nil # resets the memoization

      apply_group_state(lights: @light_ids)
    end

    def scene=(scene)
      apply_group_state(scene: scene.is_a?(Scene) ? scene.id : scene)
    end

    def <<(light_id)
      @light_ids << light_id
      apply_group_state(lights: @light_ids)
    end

    def apply_group_state(attributes)
      return if new?

      client.agent.put(url, translate_keys(attributes, GROUP_KEYS_MAP))
    end

    def apply_state(attributes)
      return if new?

      client.agent.put("#{url}/action",
                       translate_keys(attributes, STATE_KEYS_MAP))
    end

    def refresh!
      unpack(client.agent.get(url))
      self
    end

    def create!
      response  = client.agent.post(collection_url,
                                    name:   @name,
                                    lights: @light_ids)

      success   = response.find { |resp| resp.key?("success") }
      @id       = success["success"]["id"].to_i if success

      @id || response
    end

    def destroy!
      response  = client.agent.delete(url)
      success   = response.find { |resp| resp.key?("success") }
      @id       = nil if success

      @id.nil? ? true : response
    end

    def new?; @id.nil?; end

  private

    GROUP_KEYS_MAP = {
      name:       :name,
      light_ids:  :lights,
      type:       :type,
      state:      :action,
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
    }

    def unpack(data)
      @lights = nil if data[:lights]
      unpack_hash(data, GROUP_KEYS_MAP)

      return if new?

      unpack_hash(@state, STATE_KEYS_MAP)
      @light_ids = cleanse_lights(@light_ids)
      @x, @y = @state["xy"]
    end

    def cleanse_lights(light_ids)
      Array(light_ids)
        .map { |ll| ll.is_a?(Light) ? ll.id : ll.to_i }
        .sort
        .uniq
    end

    def collection_url; "#{client.url}/groups"; end
    def url; "#{collection_url}/#{id}"; end
  end
end
