require 'thor'

module Hue
  class CliBase < Thor
    def self.shared_options

      method_option :ip,
                    :type => :string,
                    :desc => 'IP address of a bridge, if known.',
                    :required => false
      method_option :user,
                    :aliases => '-u',
                    :type => :string,
                    :desc => 'Username with access to higher level functions.',
                    :default => Hue::USERNAME,
                    :required => false

    end

    def self.shared_light_options

      method_option :hue, :type => :numeric
      method_option :sat, :type => :numeric, :aliases => '--saturation'
      method_option :bri, :type => :numeric, :aliases => '--brightness'
      method_option :alert, :type => :string
      method_option :effect, :type => :string
      method_option :transitiontime, :type => :numeric

    end
  end
end
