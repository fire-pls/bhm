require_relative "errors"
require_relative "utils"

module Msh
  # The meat of the library
  module Validation
    # NOTE: Methods **MUST** be in the included block -- otherwise we pollute the module constants with
    # any "extended initializer"
    def self.included(receiver)
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
      receiver.singleton_class.define_method(:config) do |**cfg|
        pending_case, pending_keys = cfg.values_at(:casing, :keys)
        receiver.instance_variable_set(:@___assert_case, pending_case)
        receiver.instance_variable_set(:@___assert_keys, pending_keys)

        case_options = [:lower_snake, :lowerCamel, :UpperCamel, :SCREAMING_SNAKE, nil]
        fail ArgumentError, "casing must be one of #{case_options.inspect}" unless case_options.include? pending_case

        key_options = [:symbols, :strings, nil]
        fail ArgumentError, "keys must be one of #{key_options.inspect}" unless key_options.include? pending_keys
      end

      # Concise API for setting both case assertion & key conformity
      receiver.singleton_class.define_method(:keys) do |arg|
        key_option = arg.is_a?(String) ? :strings : :symbols
        receiver.config(
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
      receiver.singleton_class.define_method(:validator) do |key, handler|
        formatted_key = case receiver.instance_variable_get(:@___assert_keys)
        when :symbols then key.to_sym
        when :strings then key.to_s
        else
          key
        end

        vlds = receiver.instance_variable_get(:@___validators) || {}
        vlds[formatted_key] = handler
        receiver.instance_variable_set(:@___validators, vlds)
      end

      receiver.singleton_class.define_method(:guard) do |handler|
        grds = receiver.instance_variable_get(:@___guards) || []
        grds << handler
        receiver.instance_variable_set(:@___guards, grds)
      end

      receiver.singleton_class.define_method(:guards) do
        receiver.instance_variable_get(:@___guards) || []
      end

      receiver.singleton_class.define_method(:validators) do
        receiver.instance_variable_get(:@___validators) || {}
      end

      receiver.singleton_class.define_method(:assert_case) do
        receiver.instance_variable_get(:@___assert_case)
      end

      receiver.singleton_class.define_method(:assert_keys) do
        receiver.instance_variable_get(:@___assert_keys)
      end

      # Make getters go through config
      receiver.singleton_class.define_method(:assert_case=) do |new_case|
        receiver.config(keys: assert_keys, casing: new_case)
      end

      receiver.singleton_class.define_method(:assert_keys=) do |new_type|
        receiver.config(keys: new_type, casing: assert_case)
      end

      # TODO: Global default config here

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
    def validate_keys!
      if assert_keys
        klass = case assert_keys
        when :symbols then Symbol
        when :strings then String
        end

        keys.each do |string_or_sym|
          Errors::InvalidKeyType.raise!(receiver: self, key: string_or_sym, type: assert_keys) unless string_or_sym.is_a? klass
        end
      end

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
      validate_keys!

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
        Errors::InvalidValue.raise!(key: key, receiver: self) unless result
      rescue KeyError
        mod = (singleton_class.included_modules.select { |mod| mod.include? Validation }).first
        Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
      end
    end

    def run_guards!
      guards.each do |handler|
        result = handler.call(self)

        Errors::WontValidate.raise!(receiver: self) unless result
      end
    end
  end
end
