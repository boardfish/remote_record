# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_record/version'

Gem::Specification.new do |spec|
  spec.name          = "remote_record"
  spec.version       = RemoteRecord::VERSION
  spec.authors       = ["Simon Fish", "John Britton"]
  spec.email         = ["si@mon.fish", "public@johndbritton.com"]

  spec.summary       = %q{Ready-made remote resource structures.}
  spec.description   = %q{Allows creating local instances of objects stored on remote services.}
  spec.homepage      = "https://github.com/raisedevs/remote_record"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/raisedevs/remote_record"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'activerecord'
end
