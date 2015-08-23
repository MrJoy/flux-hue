require "yaml"
require "flux_hue/vector2"
require "flux_hue/color"

def unpack_color(col)
  if col.is_a?(String)
    Color::LaunchPad.const_get(col.upcase).to_h
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
