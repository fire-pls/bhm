# Example of a shared schema, `meta`, to be re-used in multiple places
require "bhm"

module Meta
  include Bhm::Validation
  validator :created_at, DateTime
  validator :updated_at, DateTime

  validator :uuid, ->(value) { value.match?(/\A(\{)?([a-fA-F0-9]{4}-?){8}(?(1)\}|)\z/) }
end
