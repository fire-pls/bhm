module Msh
  module Errors
    # Generic error -- the hash could not be fully validated
    class InvalidHash < KeyError
      def self.raise!(message = nil, key:, receiver:)
        message ||= "could not find key: #{key}"
        fail new(message, key: key, receiver: receiver)
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

      # From the invalid hash, get a period-joined string of keys leading to the invalid key or value
      def ref
        error_chain.map(&:key).join(".")
      end

      # TODO: Import absolute_ref
    end

    # A required value was not found
    class MissingKey < InvalidHash; end

    # The value was found, but calling `validate!` on it raised a validation error
    class InvalidValue < InvalidHash; end
  end
end
