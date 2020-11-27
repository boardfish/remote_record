require "bundler/setup"
require "remote_record"
require "remote_record/base"
require "remote_record/reference"
require "remote_record/dsl"
require "remote_record/class_lookup"
require "remote_record/config"
require 'vcr'
require 'active_record'
require 'database_cleaner'
require 'faraday'
require 'faraday_middleware'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.before :suite do
    ActiveRecord::Base.establish_connection :adapter => 'sqlite3', database: ':memory:'
  end

  config.before :each do
    DatabaseCleaner.start
  end
  config.after :each do
    DatabaseCleaner.clean
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
