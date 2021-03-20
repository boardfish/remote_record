# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/rescuable'
require 'active_record/type'
require 'remote_record/type'
require 'remote_record/base'
require 'remote_record/class_lookup'
require 'remote_record/config'
require 'remote_record/dsl'
require 'remote_record/reference'
require 'remote_record/version'
require 'remote_record/transformers'

# Generic interface for resources stored on external services.
module RemoteRecord
  extend ActiveSupport::Concern
  included do
    include Reference
    include DSL
  end

  class RecordClassNotFound < StandardError; end
end
