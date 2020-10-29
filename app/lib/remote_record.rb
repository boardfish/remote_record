# frozen_string_literal: true

# Generic interface for resources stored on external services.
module RemoteRecord
  def self.included(reference)
    reference.include Reference
    reference.extend DSL
  end
end
