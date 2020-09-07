require_relative "errors"
require_relative "utils"

module Msh
  # The meat of the library
  module Validation
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
        @___assert_case, @___assert_keys = cfg.values_at(:casing, :keys)

        case_options = [:lower_snake, :lowerCamel, :UpperCamel, :SCREAMING_SNAKE, nil]
        fail ArgumentError, "casing must be one of #{case_options.inspect}" unless case_options.include? @___assert_case

        key_options = [:symbols, :strings, nil]
        fail ArgumentError, "keys must be one of #{key_options.inspect}" unless key_options.include? @___assert_keys
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
        @___validators ||= {}
        formatted_key = case @___assert_keys
        when :symbols then key.to_sym
        when :strings then key.to_s
        else
          key
        end

        @___validators[formatted_key] = handler
      end

      # [asserted_case] The casing this hash should adhere to. Keep nil to ignore
      # must be one of the following:
      # - :lower_snake
      # - :lowerCamel
      # - :UpperCamel
      # [validators] Hash of key => handlers for validating a hash

      # Define getters for each of these methods
      %i[validators assert_case assert_keys].each do |method_name|
        define_method(method_name) { receiver.instance_variable_get("@___#{method_name}") }
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

    # Standalone checks for validity
    def guard!
    end

    # Hash of keys to validate, with the value being something which responds to `call`.
    # The `call`-able object does not need to return anything, it just needs to raise a KeyError on failure
    def validator
      {}
    end

    def validate!
      assert_case!

      guard!

      # Run validation
      run_validations!

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
    rescue Errors::InvalidHash => e
      @errors = e.error_chain
      false
    end

    private

    def run_validations!
      validators.each do |key, handler|
        hash = fetch(key)

        result = handler.call(hash)
        Errors::InvalidValue.raise!("could not validate value for key: #{key}", key: key, receiver: self) unless result
      rescue KeyError
        mod = (singleton_class.included_modules.select { |mod| mod.include? Validation }).first
        Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
      end
    end
  end
end
