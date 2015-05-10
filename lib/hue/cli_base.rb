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

    end
  end
end
