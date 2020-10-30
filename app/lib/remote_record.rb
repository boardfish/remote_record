# frozen_string_literal: true

# Generic interface for resources stored on external services.
module RemoteRecord
  extend ActiveSupport::Concern
  included do
    include Reference
  end

  class_methods do
    include DSL
  end

  class RecordClassNotFound < StandardError; end
end
