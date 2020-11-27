require_relative 'lib/remote_record/version'

Gem::Specification.new do |spec|
  spec.name          = "remote_record"
  spec.version       = RemoteRecord::VERSION
  spec.authors       = ["Simon Fish", "John Britton"]
  spec.email         = ["si@mon.fish", "public@johndbritton.com"]

  spec.summary       = %q{Ready-made remote resource structures.}
  spec.description   = %q{Ready-made remote resource structures.}
  spec.homepage      = "https://github.com/raisedevs/remote_record"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/raisedevs/remote_record"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  # spec.bindir        = "exe"
  # spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'activerecord'
end
