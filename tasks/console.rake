task :env do
  require_relative "../lib/flux_hue"
end

task console: [:env]
