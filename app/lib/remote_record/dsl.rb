# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. See the project
  # README for more on how to use this.
  module DSL
    def remote_record(options = {})
      define_method(:remote_record_config) { options }
    end
  end
end
