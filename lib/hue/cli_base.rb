require 'thor'

module Hue
  class CliBase < Thor
    class InvalidUsage < Thor::Error
      # def initialize(msg); @msg = msg; end
      # def to_s; "ERROR: #{self.class.to_s.split(/::/).last}: #{@msg}"; end
      # def backtrace; end
    end
    class NothingToDo < InvalidUsage; end
    class UnknownBridge < InvalidUsage; end
    class UnknownLight < InvalidUsage; end
    class UnknownGroup < InvalidUsage; end

    def self.shared_bridge_options
      method_option :ip,
                    type:     :string,
                    desc:     'IP address of a bridge, if known.',
                    required: false
    end

    def self.shared_access_controlled_options
      shared_bridge_options
      method_option :user,
                    aliases:  '-u',
                    type:     :string,
                    desc:     'Username with access to higher level functions.',
                    default:  Hue::Client::DEFAULT_USERNAME,
                    required: false
    end

    def self.shared_light_options
      shared_access_controlled_options
      method_option :hue,             type: :numeric
      method_option :sat,             type: :numeric, aliases: '--saturation'
      method_option :bri,             type: :numeric, aliases: '--brightness'
      method_option :alert,           type: :string
      method_option :effect,          type: :string
      method_option :transitiontime,  type: :numeric, aliases: '--time'
    end

    def self.shared_nameable_light_options
      shared_light_options
      method_option :name, type: :string
    end
  end
end
