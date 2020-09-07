require_relative "hsah/errors"
require_relative "hsah/utils"
require_relative "hsah/validation"
require_relative "hsah/version"

module Hsah
  # Quick way to start including hash validation. May be the only module some projects need :)
  module Scaffold
    prepend Hsah::Validation
    prepend Hsah::Validation::Default
  end
end
