module Hsah
  module Errors
    # Generic error -- the hash could not be fully validated
    class InvalidHash < KeyError
      # TODO: Import logic
    end

    # A required value was not found
    class MissingKey < InvalidHash; end

    # The value was found, but calling `validate!` on it raised a validation error
    class InvalidValue < InvalidHash; end
  end
end
