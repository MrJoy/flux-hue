require 'thor'

module Hue
  class CliBase < Thor
    def self.shared_options

      method_option :user,
                    :aliases => '-u',
                    :type => :string,
                    :desc => 'Username with access to higher level functions.',
                    :default => Hue::USERNAME,
                    :required => false
      # TODO: Expose IP here, and utilize it elsewhere.

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
