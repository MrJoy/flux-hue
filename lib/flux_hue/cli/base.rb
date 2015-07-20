require "forwardable"
require "thor"

module FluxHue
  module CLI
    # Base class for classes to help cleanse and format data for display.
    class Presenter
      extend Forwardable

      def initialize(entity); @entity = entity; end

    private

      def from_boolean(value); value ? "Yes" : "No"; end
    end

    # Shared functionality used in multiple places in the CLI class.
    class Base < Thor
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
                      desc:     "Registered username for restricted access.",
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

    protected

      def client
        @bridge ||= FluxHue::Bridge.all(ip: options[:ip]).first
        fail UnknownBridge unless @bridge
        @client ||= FluxHue::Client.new(@bridge, username: options[:user])
      end

      def parse_list(raw)
        (raw || "")
          .strip
          .split(/[,\s]+/)
          .map(&:to_i)
      end

      def extract_fields(ent, hsh); hsh.keys.map { |prop| ent.send(prop) }; end
      def pivot_row(rows, hsh); hsh.values.zip(rows.first); end

      def apply_sorting(rows)
        return rows unless options[:sort]

        sorting = parse_list(options[:sort])
        rows
          .sort do |a, b|
            sorting
              .map { |k| a[k] <=> b[k] }
              .find { |n| n != 0 } || 0
          end
      end

      def render_table(rows, hsh = nil)
        params            = { rows: rows }
        params[:headings] = hsh.values if hsh

        Terminal::Table.new(params)
      end
    end
  end
end
