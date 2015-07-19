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
  USERNAME_RANGE    = 10..40
  DEFAULT_USERNAME  = '1234567890'
  USERNAME_VAR      = ENV['HUE_BRIDGE_USER']
  HAVE_USERNAME_VAR = USERNAME_VAR && USERNAME_VAR != ''
  USERNAME          = HAVE_USERNAME_VAR ? USERNAME_VAR : DEFAULT_USERNAME
end
