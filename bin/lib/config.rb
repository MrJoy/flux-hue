require "yaml"
require_relative "./vector2"

def unpack_color(col)
  if col.is_a?(String)
    Widget.const_get(col.upcase).dup
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
unpack_colors_in_place!(CONFIG["simulation"]["controls"]["intensity"]["colors"])
unpack_colors_in_place!(CONFIG["simulation"]["controls"]["saturation"]["colors"])
unpack_colors_in_place!(CONFIG["simulation"]["controls"]["spotlighting"]["colors"])

unpack_vector_in_place!(CONFIG["simulation"]["nodes"]["wave2"])
unpack_vector_in_place!(CONFIG["simulation"]["nodes"]["perlin"])
