require_relative "validation"

module Msh
  # Quick way to start including hash validation. May be the only module some projects need :)
  module Scaffold
    prepend Msh::Validation
    prepend Msh::Validation::Default
  end
end
