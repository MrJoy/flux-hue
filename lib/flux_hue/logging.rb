require "logger"

LOGGER        = Logger.new(STDOUT)
LOGGER.level  = Logger.const_get((ENV["FLUX_LOGLEVEL"] || "INFO").upcase)
