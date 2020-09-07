require_relative "errors"
require_relative "utils"

module Hsah
  # The meat of the library
  module Validation
    module Default
      # NOTE: This module must be included AFTER HashValidation to ensure default validators are redefined

      ## DEFAULT VALIDATOR ##
      # Once the hash has been extended with Hsah::Validation, take the singleton_class ("1-off" modified class of our hash instance)
      # Then, find any user-defined modules which may have been nested in the class.
      # Assume these module names map to a key in the hash -- conforming to the value set in `#key_casing`
      #
      # Example: module RequestBodies => expects "requestBodies" key to be defined in `self`.
      def validator
        format = ->(sym) do
          # Retrieve the ambiguous constant
          mod = singleton_class.const_get(sym)

          # Skip it if it does not include `Validation`, or respond to include?
          next unless mod.respond_to?(:include?) && mod.include?(Hsah::Validation)

          # If the hash has not set any key_casing, assume :lower_snake
          key = Hsah::Utils.transform_module_casing(sym, key_casing || :lower_snake)

          # Instantiate the handler for validating. This block makes 2 assumptions:
          # 1. The retrieved constant is a `module`
          # 2. The retrieved module exposes the `#validate!` instance method, which errs on failure
          handler_lambda = ->(h) { h.extend(mod).validate! }

          # Output, [key, handler_lambda]
          [key, handler_lambda]
        end

        # Drop any `nil` we may have gotten from our `next` call
        singleton_class.constants.map(&format).compact.to_h
      end
    end

    # The casing this hash should adhere to. Keep nil to
    # must be one of the following:
    # - :lower_snake
    # - :lowerCamel
    # - :UpperCamel
    def key_casing
    end

    # TODO: Assert the keys hash conform to a casing stantard
    def assert_case!
      case key_casing
      when nil
        # Ignore casing
      when :lowerCamel
        # TODO
      when :UpperCamel
        # TODO
      when :lower_snake
        # TODO
      else
        fail ArgumentError, "unsupported casing: #{key_casing}"
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
      validator.each do |key, handler|
        hash = fetch(key)

        result = handler.call(hash)
        Errors::InvalidValue.raise!("could not validate value for key: #{key}", key: key, receiver: self) unless result
      rescue KeyError
        mod = (singleton_class.included_modules.select { |mod| mod.include? Hsah::Validation }).first
        Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
      end
    end
  end
end
