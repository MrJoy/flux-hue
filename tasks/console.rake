task :env do
  require_relative "../lib/sparkle_motion"
end

task console: [:env]
