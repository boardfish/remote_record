# frozen_string_literal: true

module RemoteRecord
  # Remote record types should inherit from this class and define #get.
  class Base
    def self.config
      {
        authorization: proc {},
        caching: false
      }
    end

    def initialize(reference, **options)
      @reference = reference
      @options = options
    end

    def get
      raise NotImplementedError
    end

    private

    def authorization
      authz = @options.fetch(:authorization)
      authz.respond_to?(:call) ? authz.call(@reference, @options) : authz
    end

    def remote_resource_id
      @reference.send(@options.fetch(:id_field))
    end
  end
end
