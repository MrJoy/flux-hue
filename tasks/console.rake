task :env do
  require_relative "../bin/lib/flux_hue"
end

task console: [:env]
