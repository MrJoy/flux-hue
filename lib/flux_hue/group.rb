module FluxHue
  # Models a group of lights in the Hue system, providing means of
  # applying changes to multiple lights at once.
  class Group
    include TranslateKeys
    include EditableState

    # The Client (and by extension, Bridge) this group is associated with.
    attr_reader :client

    # Various properties provided by the bridge.
    attr_reader :id, :name, :hue, :saturation, :brightness, :x, :y,
                :color_temperature, :type

    attr_reader :light_ids

    def initialize(client:, id: nil, name: nil, lights: nil, data: {})
      @client     = client
      @id         = id
      @state      = {}
      @light_ids  = cleanse_lights(lights)
      @name       = name

      unpack(data)
    end

    def lights; @lights ||= @light_ids.map { |ll| @client.light(ll) }; end

    def name=(name)
      @name = agent
              .successes(apply_group_state("name" => name))
              .first["/groups/#{id}/name"]
    end

    def lights=(light_ids)
      @light_ids  = cleanse_lights(light_ids)
      @lights     = nil # resets the memoization

      apply_group_state("lights" => @light_ids)
    end

    def <<(light_id)
      @light_ids << light_id
      apply_group_state("lights" => @light_ids)
    end

    def apply_group_state(attrs)
      return if new?

      agent.put(url, translate_keys(attrs, GROUP_KEYS_MAP))
    end

    def apply_state(attrs)
      return if new?

      agent.put("#{url}/action", translate_keys(attrs, STATE_KEYS_MAP))
    end

    def refresh!
      unpack(agent.get(url))
      self
    end

    def create!
      response  = agent.post(collection_url, "name"   => @name,
                                             "lights" => @light_ids)

      success   = agent.successes(response).first
      @id       = success["id"].to_i if success

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
      @lights = nil if data["lights"]
      unpack_hash(data, GROUP_KEYS_MAP)

      return if new?

      unpack_hash(@state, STATE_KEYS_MAP)
      @id         = @id.to_i if @id
      @light_ids  = cleanse_lights(@light_ids)
      @x, @y      = @state["xy"]
    end

    def cleanse_lights(ids)
      Array(ids).map { |ll| ll.is_a?(Light) ? ll.id : ll }.map(&:to_i).sort.uniq
    end

    def agent; client.agent; end
    def collection_url; "#{client.url}/groups"; end
    def url; "#{collection_url}/#{id}"; end
  end
end
