module SparkleMotion
  # Class to represent configurations and positioning of lights.
  class LightConfig
    attr_accessor :bridges, :lights, :masks

    def initialize(config:, groups:)
      groups = Array(groups)

      index             = 0
      masks_by_bridge   = {}
      lights_by_bridge  = {}
      num_lights        = 0
      groups.each do |group|
        group_config  = config["light_groups"][group]
        num_lights   += group_config.length

        group_config.each_with_index do |(bridge_name, light_id, kind), idx|
          lights_by_bridge[bridge_name] ||= []
          lights_by_bridge[bridge_name] << [idx, light_id, kind]
        end
      end

      lights_by_bridge.each do |(bridge_name, lights)|
        masks_by_bridge[bridge_name] = mask_lights(lights, num_lights)
      end

      set_state!(config, lights_by_bridge, masks_by_bridge)
    end

  protected

    def set_state!(config, lights, masks)
      @bridges  = config["bridges"]
      @lights   = lights
      @masks    = masks
    end

    # Create a mask for the global set of lights to easily tell which ones
    # belong to a given bridge.
    def mask_lights(indexed_lights, length)
      mask = [false] * length
      indexed_lights.map(&:first).each { |idx| mask[idx] = true }
      mask
    end
  end
end
