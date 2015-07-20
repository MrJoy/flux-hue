require "thor"

module FluxHue
  # Shared functionality used in multiple places in the CLI class.
  class CLIBase < Thor
    class InvalidUsage < Thor::Error; end
    class NothingToDo < InvalidUsage; end
    class UnknownBridge < InvalidUsage; end
    class UnknownLight < InvalidUsage; end
    class UnknownGroup < InvalidUsage; end

    def self.shared_bridge_options
      method_option :ip,
                    type:     :string,
                    desc:     "IP address of a bridge, if known.",
                    required: false
    end

    def self.shared_access_controlled_options
      shared_bridge_options
      method_option :user,
                    aliases:  "-u",
                    type:     :string,
                    desc:     "Username with access to higher level functions.",
                    default:  FluxHue::Client::DEFAULT_USERNAME,
                    required: false
    end

    def self.shared_light_options
      shared_access_controlled_options
      method_option :hue,             type: :numeric
      method_option :sat,             type: :numeric, aliases: "--saturation"
      method_option :bri,             type: :numeric, aliases: "--brightness"
      method_option :alert,           type: :string
      method_option :effect,          type: :string
      method_option :transitiontime,  type: :numeric, aliases: "--time"
    end

    def self.shared_nameable_light_options
      shared_light_options
      method_option :name, type: :string
    end
  end
end
