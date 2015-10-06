module SparkleMotion
  module CLI
    # Crude, simplistic option parser that really should be replaced with something off the shelf.
    class ArgumentParser
      attr_reader :options
      ARGUMENT_PATTERN = /\A--(?<name>[^=]+)(=(?<value>.*))?\z/

      def initialize(defaults)
        @defaults = defaults
        @kinds    = {}
        @required = Hash[]
        @allowed  = Hash[]
        @handlers = {}
        @kinds_encountered = Set.new
        @errors   = false
      end

      def parse!(argv)
        options = @defaults.dup
        flags, other = extract_arguments(argv)
        flags.each do |(arg, name, kind, value)|
          break unless check_arg!(arg, name, kind, value)
          @handlers[name].call(value, options, name)
        end

        check_results!

        [options, other]
      end

      def require!(*names)
        Array(names).flatten.each do |name|
          @required[name] = false
        end
        self
      end

      def allow!(name, allowed: nil, kind: nil, &handler)
        @handlers[name] = handler || proc { |value, result| result[name] = value || true }
        @kinds[name]    = kind if kind
        @allowed[name]  = allowed.nil? ? true : allowed
        self
      end

    protected

      def check_arg!(arg, name, kind, value)
        @required[name] = @required[kind] = true
        [allowed?(arg, name, value),
         kind_unencountered?(kind)].all?
      end

      def allowed?(arg, name, value)
        allowed = @allowed[name]
        result = allowed.respond_to?(:include?) ? allowed.include?(value) : allowed
        unrecognized_arg!(arg) unless allowed
        invalid_value!(name, value, allowed) if allowed && !result
        result
      end

      def kind_unencountered?(kind)
        unencountered = !@kinds_encountered.include?(kind)
        incompatible_args!(kind) unless unencountered
        @kinds_encountered << kind
        unencountered
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

      def incompatible_args!(kind)
        @errors = true
        LOGGER.error { "Must specify only one #{kind} parameter!" }
      end

      def invalid_value!(name, value, allowed)
        error! do
          prefix = "Got invalid value ('#{value}') for #{name}!"
          case [allowed.respond_to?(:include?), allowed.is_a?(Range)]
          when [true, true] then "#{prefix}  Must be within #{allowed.first}..#{allowed.last}."
          when [true, false] then "#{prefix}  Must be one of: #{allowed.join(', ')}."
          else
            prefix
          end
        end
      end

      def unrecognized_arg!(arg)
        error! { "Unrecognized parameter: #{arg}" }
      end

      def missing_arg!(name)
        error! { "Must specify #{@kinds.value?(name) ? "an #{name} argument" : name}!" }
      end

      def error!(&message)
        @errors = true
        LOGGER.error(&message)
      end
    end
  end
end
