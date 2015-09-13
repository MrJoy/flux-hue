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
    cfg[key] = SparkleMotion::Vector2.new(val)
  end
end

CONFIG = YAML.load_file("config.yml")
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
