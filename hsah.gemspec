require_relative "lib/hsah/version"
require "date"

Gem::Specification.new do |gemspec|
  gemspec.name = "hsah"
  gemspec.version = Hsah::VERSION
  gemspec.required_ruby_version = ">= #{IO.read("./.ruby-version").strip}"
  gemspec.required_rubygems_version = Gem::Requirement.new(">= 2.7.4")

  gemspec.date = Date.today.strftime("%Y-%m-%d")
  gemspec.authors = ["Trevor James"]
  gemspec.email = "trevor@osrs-stat.com"

  gemspec.summary = "Modular hash validation"

  gemspec.homepage = "https://github.com/fire-pls/hsah"
  gemspec.license = "MIT"

  # Files to include when publishing gem
  gemspec.files = Dir["LICENSE", "README.md", "examples/**/*", "lib/**/*"]
  gemspec.require_path = "lib"

  # Files which can be executed with bundle exec
  # gemspec.bindir = "bin"

  # Dependencies
  # None :)

  # Dev Dependencies
  gemspec.add_development_dependency "amazing_print"
  gemspec.add_development_dependency "pry-byebug"
  gemspec.add_development_dependency "rake"
  gemspec.add_development_dependency "rspec", "~> 3.4"
  gemspec.add_development_dependency "standard"
end
