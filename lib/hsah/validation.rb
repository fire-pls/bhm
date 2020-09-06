require "errors"

module Hsah
  # The meat of the library
  module Validation
    def key_casing
      :lower_snake_case
    end

    # TODO: Assert the hash conforms to a casing stantard
    def assert_case!
      case key_casing
      when :lower_snake_case
        nil
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
        fetch(key, {}).tap do |hash|
          handler.call(hash)
        rescue KeyError
          # TODO: Ensure any extra hash extensions are ignored here
          mod = (singleton_class.included_modules - Hash.included_modules).first
          Errors::InvalidHash.raise!("could not validate: #{mod}", key: key, receiver: self)
        end
      end
    end
  end
end
