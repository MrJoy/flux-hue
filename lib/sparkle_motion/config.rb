# TODO: Load this on-demand, not automatically!  Namespace it!  AUGH!
CONFIG = YAML.load(ERB.new(File.read("config.yml"), nil, "-").result(binding))
CONFIG["bridges"].map do |name, cfg|
  cfg["name"] = name
end
