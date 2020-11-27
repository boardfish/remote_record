# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'remote_record/version'

Gem::Specification.new do |spec|
  spec.name                  = 'remote_record'
  spec.version               = RemoteRecord::VERSION
  spec.authors               = ['Simon Fish', 'John Britton']
  spec.email                 = ['si@mon.fish', 'public@johndbritton.com']

  spec.summary               = 'Ready-made remote resource structures.'
  spec.description           = 'Allows creating local instances of objects stored on remote services.'
  spec.homepage              = 'https://github.com/raisedevs/remote_record'
  spec.license               = 'MIT'

  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/raisedevs/remote_record'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir['LICENSE.txt', 'README.md', 'lib/**/*']
  spec.require_paths = ['lib']
  spec.add_runtime_dependency 'activerecord'
  spec.add_runtime_dependency 'activesupport'
end
