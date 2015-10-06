module SparkleMotion
  module Simulation
    # The Parameters class holds the current state of any defined parameters, handles
    # persisting/loading them from disk, and via callbacks acts as a means to bind widgets and
    # simulations together.
    class Parameters
      # Helper representing an individual parameter, its state, and any relevant callbacks.
      class Parameter
        attr_reader :name, :value, :callbacks
        def initialize(name, value, &initializer)
          @name         = name
          @value        = value
          @callbacks    = []
          @calling      = false
          @initializer  = initializer
        end

        def value=(val)
          return if value == val || @calling
          @value = val
          on_change
        end

        def init!; on_change(true); end

      protected

        def on_change(init = false)
          @calling = true
          @callbacks.each { |cb| cb.call(@name, @value) }
          @initializer.call(@name, @value) if init && @initializer
        ensure
          @calling = false
        end
      end

      attr_accessor :enabled

      def initialize(filename, logger)
        @logger     = logger
        @filename   = filename
        @enabled    = false
        @parameters = Hash.new do |_data, key|
          @logger.warn { "Parameters[#{key}]: Unrecognized key!" }
          nil
        end
      end

      def init!
        @parameters.values.map(&:init!)
      end

      def save!
        return unless @enabled
        @logger.debug { "Parameters: Persisting state." }
        # TODO: Maybe keep the file open, and rewind?
        File.open(@filename, "w") do |fh|
          fh.write(Hash[@parameters.values.map { |pp| [pp.name, pp.value] }].to_yaml)
        end
      end

      def load!
        return unless File.exist?(@filename)
        @logger.debug { "Parameters: Restoring state." }
        check_age
        perform_load!
      end

      def check_age
        age = Time.now.to_f - File.stat(@filename).mtime.to_f
        return unless age > 3600
        logger.warn do
          "Parameters: #{@filename} is #{age} seconds old!"\
            "  Probably NOT what you want, but you're the boss..."
        end
      end

      def parameter!(key, default, &initializer)
        fail "Tried to re-register parameter: #{key}!" if @parameters.key?(key)
        @parameters[key] = Parameter.new(key, default, &initializer)
        @parameters[key].callbacks << proc { save! }
      end

      def on_change(key, &callback)
        param = @parameters[key]
        return nil unless param
        param.callbacks << callback
      end

      def [](key)
        param = @parameters[key]
        return nil unless param
        param.value
      end

      def []=(key, value)
        param = @parameters[key]
        return nil unless param
        param.value = value
      end

    protected

      def perform_load!
        (YAML.load_file(@filename) || {})
          .each do |key, value|
            @parameters[key].value = value if @parameters.key?(key)
          end
      rescue Psych::SyntaxError => pse
        LOGGER.error { "Parameters: Error parsing state file!" }
        LOGGER.error { pse }
      end
    end
  end
end
