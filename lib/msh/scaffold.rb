require_relative "utils"
require_relative "validation"

module Msh
  # Quick way to start including hash validation. May be the only module some projects need :)
  module Scaffold
    # Upon being included do the following:
    # - define any validators based on the declared instance_variables
    # (then)
    # - fetch all declared modules
    ## And recursively do the following:
    ## - extend it with Msh::Validation
    ## - define a new validator, using the module name as a key
    ## (a nested module assumes it's a nested hash)
    #### @mod_name = ->(hash) { hash.extend(ModName).validate! }
    def self.included(klass)
      # Include the validation suite in self
      klass.include(Validation)

      # Find all modules (we are assuming these are hashes)
      klass.constants.each do |sym|
        const = const_get([klass, sym].join("::"))
        next unless const.is_a?(Module)

        # Then, define the validator for the current class (calls validate! on the hash)
        # default_key_case may return `nil` if no global config is set.
        casing_transform = klass.default_key_case || :lower_snake
        key = Msh::Utils.transform_module_casing(sym, casing_transform, klass.default_key_type)

        klass.validator key, ->(hash) { hash.extend(const).validate! }

        # Lastly, recursively include the scaffolding suite in these child modules
        const.include(Scaffold)
      end
    end
  end
end

# Usage:
# 1. Define a group of nested modules:
# module Apex
#   module Hash1
#     module NestedHash
#       # IF this nested hash is the bottommost "leaf", we will not traverse any further.
#       # Defining instance variables is still respected
#   module Hash2
#     module NestedHash

# TODO: Consider adding a GLOBAL LIB config for assumed hash casing & key type
# example:
#
# Msh.default_keys = :SCREAMING_SNAKE
#
# +or+
#
# Msh.default_config = { keys: :symbols, casing: :SCREAMING_SNAKE }
