# frozen_string_literal: true

module RemoteRecord
  # Remote record types should inherit from this class and define #get.
  class Base
    def self.default_config
      Config.new(remote_record_klass: self)
    end

    def initialize(reference, options)
      @reference = reference
      @options = options.presence || default_config
    end

    def get
      raise NotImplementedError
    end

    private

    def authorization
      authz = @options.authorization
      authz.respond_to?(:call) ? authz.call(@reference, @options) : authz
    end

    def remote_resource_id
      @reference.send(@options.id_field)
    end
  end
end
