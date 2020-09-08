module Msh
  module Errors
    module Chainable
      # Helper for re-raising easily
      def self.included(klass)
        # Add new class method, without needing to prepend the class
        klass.define_singleton_method(:raise!) do |*args, **kwargs|
          fail new(args[0], **kwargs)
        end
      end

      # Retrieve the chain of errors up to the most recent included module
      # Eg.
      # hash.extend(Document)
      # error_chain == [Document, Components, Schemas, Primitive]
      #
      # hash.extend(Document::Components)
      # error_chain == [Components, Schemas, Primitive]
      def error_chain
        @error_chain ||= -> {
          out, parent = [self], cause
          loop do
            break out if parent.nil?
            out.push(parent)
            parent = parent.cause
          end
        }.call
      end
    end

    # Pre-validation check indicates this should not be validated
    class WontValidate < ArgumentError
      include Chainable
      attr_accessor :receiver
      def initialize(message = nil, receiver:)
        message ||= "A guard raised; Will not attempt validation for this hash"
        err = new(message)
        err.receiver = receiver
        super(message)
      end
    end

    # Generic error -- the hash could not be fully validated
    class InvalidHash < KeyError
      include Chainable
      def initialize(message = nil, receiver:, key:)
        message ||= "the hash could not be fully validated"
        super(message, receiver: receiver, key: key)
      end

      # From the invalid hash, get a period-joined string of keys leading to the invalid key or value
      def ref
        error_chain.map(&:key).join(".")
      end

      # TODO: Import absolute_ref
    end

    # The key does not adhere to the asserted key typing
    class InvalidKeyType < InvalidHash
      def initialize(message = nil, receiver:, key:, type:)
        message ||= "all keys must be #{type} (got #{key.inspect})"
        super(message, receiver: receiver, key: key)
      end
    end

    # The key does not adhere to the asserted key casing
    class InvalidKeyCasing < InvalidHash
      def initialize(message = nil, receiver:, key:, casing:)
        message ||= "the key #{key.inspect} is not in #{casing} casing"
        super(message, receiver: receiver, key: key)
      end
    end

    # A required value was not found
    class MissingKey < InvalidHash
      def initialize(message = nil, receiver:, key:)
        message ||= "could not find key: #{key.inspect}"
        super(message, receiver: receiver, key: key)
      end
    end

    # The value was found, but calling `validate!` on it raised a validation error
    class InvalidValue < InvalidHash
      def initialize(message = nil, receiver:, key:)
        message ||= "a value exists for key #{key.inspect} -- but it did not pass validation"
        super(message, receiver: receiver, key: key)
      end
    end
  end
end
