# frozen_string_literal: true

module RemoteRecord
  # Remote record classes should inherit from this class and define #get.
  class Base
    def self.default_config
      Config.defaults.merge(remote_record_class: self)
    end

    def initialize(reference, options)
      @reference = reference
      @options = options.presence || default_config
      @attrs = HashWithIndifferentAccess.new
    end

    def method_missing(method_name, *_args, &_block)
      @attrs.fetch(method_name)
    rescue KeyError
      super
    end

    def respond_to_missing?(method_name, _include_private = false)
      @attrs.key?(method_name)
    end

    def get
      raise NotImplementedError
    end

    def fetch
      @attrs.update(get)
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
