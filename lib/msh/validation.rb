require_relative "errors"
require_relative "utils"

module Msh
  # The meat of the library
  module Validation
    def self.included(receiver)
      # Define a setter on the module including Msh::Validation
      # Allows for this in the body definition:
      # validator "key", ->(v){ v == "valid" }
      receiver.singleton_class.define_method(:validator) do |key, handler|
        @_validators ||= {}
        @_validators[key] = handler
      end

      # Define a setter on the module
      receiver.singleton_class.define_method(:keys) { |casing| @_asserted_case = casing }

      # [asserted_case] The casing this hash should adhere to. Keep nil to ignore
      # must be one of the following:
      # - :lower_snake
      # - :lowerCamel
      # - :UpperCamel
      # [validators] Hash of key => handlers for validating a hash

      # Define getters for each of these methods
      %i[validators asserted_case].each do |method_name|
        define_method(method_name) { receiver.instance_variable_get("@_#{method_name}".to_sym) }
      end
    end

    # TODO: Assert the keys hash conform to a casing stantard
    def assert_case!
      case asserted_case
      when nil
        # Ignore casing
      when :lowerCamel
        # TODO
      when :UpperCamel
        # TODO
      when :lower_snake
        # TODO
      else
        fail ArgumentError, "unsupported casing: #{asserted_case}"
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
      _runner

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

    def _runner
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
