# Example of validating a team resource, using the validation helpers
require "bhm"
require "date"
require_relative "meta"
require_relative "user"

module Team
  include Bhm::Validation
  validator :name, String
  validator :rank, Integer
  validator :users, ->(value) { value.is_a?(Array) && value.each { |user_hash| user_hash.extend(User).validate! } }

  module Budget
    include Bhm::Validation

    validator :amount, Integer
    validator :meta, ->(value) { value.extend(Meta).validate! }
  end

  validator :meta, ->(value) { value.extend(Meta).validate! }
end
