# Example of validating a user resource, using scaffolding
require "bhm"
require_relative "meta"

module User
  @name = String
  @email = ->(value) { value.is_a?(String) && value.match?(/[^\s]@[^\s]/) }
  @tos_acceptance = TrueClass
  module Address
    @street = String
  end

  module Profile
    @introduction = ->(value) { value.is_a?(String) && value.length < 255 }
    @hobbies = Array
  end

  @meta = ->(value) { value.extend(Meta).validate! }
end

User.include(Bhm::Scaffold)
