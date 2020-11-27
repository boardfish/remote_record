# frozen_string_literal: true

require 'active_support/concern'
require 'remote_record/base'
require 'remote_record/class_lookup'
require 'remote_record/config'
require 'remote_record/dsl'
require 'remote_record/reference'
require 'remote_record/version'

# Generic interface for resources stored on external services.
module RemoteRecord
  extend ActiveSupport::Concern
  included do
    include Reference
    include DSL
  end

  class RecordClassNotFound < StandardError; end
end
