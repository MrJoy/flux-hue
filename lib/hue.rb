require 'hue/version'
require 'hue/errors'
require 'hue/client'
require 'hue/bridge'
require 'hue/editable_state'
require 'hue/translate_keys'
require 'hue/light'
require 'hue/group'
require 'hue/scene'

module Hue
  USERNAME_RANGE = 10..40
  USERNAME = (ENV['HUE_BRIDGE_USER'] && ENV['HUE_BRIDGE_USER'] != '') ? ENV['HUE_BRIDGE_USER'] : '1234567890'
end
