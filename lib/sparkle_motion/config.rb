# TODO: Load this on-demand, not automatically!  Namespace it!  AUGH!
require "sparkle_motion/vector2"
require "sparkle_motion/launch_pad/color"

def unpack_color(col)
  if col.is_a?(String)
    SparkleMotion::LaunchPad::Color.const_get(col.upcase).to_h
  else
    { r: ((col >> 16) & 0xFF),
      g: ((col >> 8) & 0xFF),
      b: (col & 0xFF) }
  end
end

def unpack_colors_in_place!(cfg)
  cfg.each do |key, val|
    if val.is_a?(Array)
      cfg[key] = val.map { |vv| unpack_color(vv) }
    else
      cfg[key] = unpack_color(val)
    end
  end
end

def unpack_vector_in_place!(cfg)
  cfg.each do |key, val|
    next unless val.is_a?(Array) && val.length == 2
    cfg[key] = Vector2.new(x: val[0], y: val[1])
  end
end

module SparkleMotion
  # Class for parsing and accessing configuration data.
  class Config
    # Base class for configuration file parsers.
    class Parser
    protected

      def unpack_vector_in_place!(cfg)
        cfg.each do |key, val|
          next unless val.is_a?(Array) && val.length == 2
          cfg[key] = Vector2.new(x: val[0], y: val[1])
        end
      end

      def load(fname); YAML.load(File.read(fname)); end

      def extract_and_solidify(raw, *keys)
        keys = Array(keys)
        Hash[keys.map { |key| [key.to_sym, OpenStruct.new(raw[key])] }]
      end
    end

    # Helper class to parser `lights.yml` files.
    class LightParser < Parser
      def parse(fname)
        # TODO: Check bridge names in lights element!
        raw               = load(fname)
        raw["lights"]     = annotate_lights(raw["lights"])
        raw["bridges"]    = annotate_bridges(raw["bridges"])
        raw["groups"]     = annotate_groups(Set.new(raw["lights"].keys), raw["groups"])
        build_light_config(raw)
      end

    protected

      def check_light_names!(available_lights, group, lights)
        lights_tmp = Set.new(lights)

        misses = (lights_tmp - available_lights).to_a.sort
        return unless misses.length > 0
        fail "Light Group '#{group}' contained unknown lights: #{misses.join(', ')}"
      end

      def build_light_config(raw)
        raw["bridges"] = Hash[raw["bridges"].map { |name, config| [name, OpenStruct.new(config)] }]
        extract_and_solidify(raw, "bridges", "lights", "groups")
      end

      def annotate_lights(lights)
        Hash[lights.map do |name, cfg|
          [name,
           OpenStruct.new(name:   name,
                          bridge: cfg[0],
                          index:  cfg[1])]
        end]
      end

      def annotate_groups(available_lights, groups)
        Hash[groups.map do |name, lights|
          lights.flatten!
          check_light_names!(available_lights, name, lights)
          [name,
           OpenStruct.new(name:   name,
                          lights: lights)]
        end]
      end

      def annotate_bridges(bridges)
        bridges.map { |name, cfg| cfg["name"] = name }
      end
    end

    # Helper class to parse `simulations.yml` files.
    class SimulationParser < Parser
      def parse(lights, fname)
        # TODO: Check bridge names in lights element!
        raw = load(fname)
        raw["simulations"].each do |_name, config|
          config["nodes"].values.each do |cfg|
            next unless cfg
            unpack_vector_in_place!(cfg)
          end
        end

        build_simulation_config(lights, raw)
      end

    protected

      def build_simulation_config(groups, raw)
        tmp = {}
        raw["simulations"].each do |name, config|
          output            = config["output"]
          group             = groups[output["group"]]
          fail "Simulation '#{name}', group '#{output.group}' doesn't exist!" unless group
          nodes             = vivify_nodes_for_simulation(group.lights.length, config)
          output["source"]  = nodes[output["from"]]
          tmp[name] = OpenStruct.new(name:         name,
                                     color_bender: OpenStruct.new(config["color_bender"]),
                                     nodes:        Hash[nodes],
                                     output:       OpenStruct.new(output))
        end

        { simulations: OpenStruct.new(tmp) }
      end

      def vivify_nodes_for_simulation(num_lights, config)
        nodes = config["nodes"]
                .map { |name, cfg| [name, [node_for(name, cfg), cfg["from"]]] }
        bind_nodes(Hash[nodes], num_lights)
      end

      def bind_nodes(nodes, num_lights)
        result = nodes
                 .map do |name, (node, from)|
                   node.lights = num_lights
                   node.source = nodes[from].first if from
                   [name, node]
                 end
        Hash[result]
      end

      def node_for(node_name, config)
        node      = Kernel.const_get("::SparkleMotion::Nodes::#{config['class']}").new
        node.name = node_name
        config.each do |key, val|
          node.send("#{key}=", val) if node.respond_to?("#{key}=")
        end
        node
      end
    end

    def self.init_lights!(fname = "lights.yml")
      (@config ||= {}).merge!(LightParser.new.parse(fname))
    end

    def self.init_simulations!(fname = "simulations.yml")
      (@config ||= {}).merge!(SimulationParser.new.parse(@config[:groups], fname))
    end

    def self.bridges; @bridges ||= @config[:bridges].to_h.values; end
    def self.bridge; @config[:bridges]; end
    def self.lights; @lights ||= @config[:lights].to_h.values; end
    def self.light; @config[:lights]; end
    def self.groups; @groups ||= @config[:groups].to_h.values; end
    def self.group; @config[:groups]; end

    def self.simulations; @simulations ||= @config[:simulations].to_h.values; end
    def self.simulation; @config[:simulations]; end
  end
end

CONFIG = YAML.load(File.read("config.yml"))
CONFIG["bridges"].map do |name, cfg|
  cfg["name"] = name
end

CONFIG["simulation"]["controls"].values.each do |cfg|
  next unless cfg && cfg["colors"]
  unpack_colors_in_place!(cfg["colors"])
end

CONFIG["simulation"]["nodes"].values.each do |cfg|
  next unless cfg
  unpack_vector_in_place!(cfg)
end
