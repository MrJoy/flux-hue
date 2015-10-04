module SparkleMotion
  module CLI
    # Crude, simplistic option parser that really should be replaced with something off the shelf.
    class ArgumentParser
      attr_reader :options
      ARGUMENT_PATTERN = /\A--(?<name>[^=]+)(=(?<value>.*))?\z/

      def initialize(defaults:, kinds:, allowed:, required:)
        @defaults = defaults
        @kinds    = {}
        kinds.each do |kind, names|
          names.each do |name|
            @kinds[name.to_sym] = kind.to_sym
          end
        end
        @required = Hash[required.map(&:to_sym).map { |name| [name, false] }]
        @allowed  = Set.new(allowed.map(&:to_sym))
        @errors   = false
      end

      def parse!(argv, &handler)
        options = @defaults.dup
        flags, other = extract_arguments(argv)
        flags.each do |(arg, name, kind, value)|
          break unless check_arg(arg, name, kind)
          handler.call(name, value, options)
        end

        check_results!

        [options, other]
      end

      def incompatible_args!(kind)
        @errors = true
        LOGGER.error { "Must specify only one #{kind} parameter!" }
      end

    protected

      def check_arg(arg, name, kind)
        @required[name] = @required[kind] = true
        return true if @allowed.include?(name)
        unrecognized_arg!(arg)
        false
      end

      def check_results!
        @required
          .to_a
          .reject { |(_name, present)| present }
          .map(&:first)
          .each do |name|
            missing_arg!(name)
          end

        exit 1 if @errors
      end

      def extract_arguments(argv)
        args  = match_args(argv)
        flags = organize_args(args.select { |(_arg, match)| match })
        other = args.reject { |(_arg, match)| match }.map(&:first)
        [flags, other]
      end

      def match_args(argv)
        argv.map { |arg| [arg, ARGUMENT_PATTERN.match(arg)] }
      end

      def organize_args(args)
        args
          .map { |(arg, match)| [arg, match[:name].tr("-", "_").to_sym, match[:value]] }
          .map { |(arg, name, value)| [arg, name, @kinds.key?(name) ? @kinds[name] : name, value] }
      end

      def unrecognized_arg!(arg)
        @errors = true
        LOGGER.error { "Unrecognized parameter: #{arg}" }
      end

      def missing_arg!(name)
        @errors = true
        LOGGER.error { "Must specify #{@kinds.value?(name) ? "an #{name} argument" : name}!" }
      end
    end
  end
end
