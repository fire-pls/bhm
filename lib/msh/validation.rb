require_relative "errors"
require_relative "utils"

module Msh
  # The meat of the library
  module Validation
    module Initializer
      # Minimal config for key case validation + hash key types.
      # Supplying no config will not validate hash keys!
      # Ie, the vaildators must map 1:1 with the hash key value:
      #
      #   validator :foo, ->(v){}
      #
      # Will look for :foo (symbol). Whereas:
      #
      #   config { keys: :strings }
      #   validator :foo, ->(v){}
      #
      # Will look for a key "foo" (string)
      def config(**cfg)
        @___assert_case, @___assert_keys = cfg.values_at(:casing, :keys)

        case_options = [:lower_snake, :lowerCamel, :UpperCamel, :SCREAMING_SNAKE, nil]
        fail ArgumentError, "casing must be one of #{case_options.inspect}" unless case_options.include? @___assert_case

        key_options = [:symbols, :strings, nil]
        fail ArgumentError, "keys must be one of #{key_options.inspect}" unless key_options.include? @___assert_keys
      end

      # Concise API for setting both case assertion & key conformity
      def keys(arg)
        key_option = arg.is_a?(String) ? :strings : :symbols
        config(
          keys: key_option,
          casing: arg.to_sym
        )
      end

      # Define a setter on the module including Msh::Validation
      # Allows for this:
      # module Apex
      #   include Msh::Validation
      #     validator "key", ->(v){ v == "valid" }
      #     validator "foo", ->(v){ v == "bar" }
      #
      # Basically, a more legibile way for us to write this:
      # module Apex
      #   include Msh::Validation
      #   @___validators = {
      #     "key" => ->(val) { val == "valid" },
      #     "foo" => ->(val) { val == "bar" },
      #   }
      #
      # Lastly; Why prefix with 3 underscores? Surely 1 or 2 is sufficient?
      # 1 (buzz)word: GraphQL. Aside from that, it's just an extra "assurance" there are no conflicting values
      def validator(key, handler)
        formatted_key = case @___assert_keys
        when :symbols then key.to_sym
        when :strings then key.to_s
        else
          key
        end

        validators[formatted_key] = handler
      end

      def guard(handler)
        guards << handler
      end

      def guards
        @__guards ||= []
      end

      def validators
        @___validators ||= {}
      end

      def assert_case
        @___assert_case
      end

      def assert_keys
        @___assert_keys
      end
    end

    def self.included(receiver)
      receiver.extend Initializer
      # Define getters for each of these methods
      %i[validators guards assert_case assert_keys].each do |method_name|
        define_method(method_name) do
          singleton_class.included_modules.find { |mod|
            mod.include? Validation
          }.public_send(method_name)
        end
      end
    end

    # TODO: Assert the keys hash conform to a casing stantard
    def assert_case!
      case assert_case
      when :lower_snake
        # TODO
      when :lowerCamel
        # TODO
      when :UpperCamel
        # TODO
      when :SCREAMING_SNAKE
        # TODO
      end
    end

    def validate!
      assert_case!

      run_guards!

      # Run validation
      run_validators!

      # If we reach this line, the schema is valid.
      self
    end

    def errors
      @errors ||= []
    end

    def valid?
      @errors = []
      return true if validate!

      # Only rescue lib-defined classes here. Let all other errors surface
    rescue Errors::InvalidHash, Errors::WontValidate => e
      @errors = e.error_chain
      false
    end

    private

    def run_validators!
      validators.each do |key, handler|
        hash = fetch(key)

        result = handler.call(hash)
        Errors::InvalidValue.raise!("could not validate value for key: #{key}", key: key, receiver: self) unless result
      rescue KeyError
        mod = (singleton_class.included_modules.select { |mod| mod.include? Validation }).first
        Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
      end
    end

    def run_guards!
      guards.each do |handler|
        result = handler.call(self)

        Errors::WontValidate.raise!(nil, receiver: self) unless result
      end
    end
  end
end
