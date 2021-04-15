# frozen_string_literal: true

require 'database_cleaner'
require 'remote_record'
require 'remote_record/collection'
require 'remote_record/config'
require 'remote_record/type'
require 'remote_record/base'
require 'remote_record/reference'
require 'remote_record/dsl'
require 'remote_record/class_lookup'
require 'vcr'
require 'active_record'
require 'faraday'
require 'faraday_middleware'
require 'webmock/rspec'
require_relative 'support/prepare_db'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
