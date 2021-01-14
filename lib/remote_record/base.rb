# frozen_string_literal: true

module RemoteRecord
  # Remote record classes should inherit from this class and define #get.
  class Base
    include ActiveSupport::Rescuable

    def self.default_config
      Config.defaults.merge(remote_record_class: self)
    end

    def initialize(reference, options = default_config, initial_attrs = {})
      @reference = reference
      @options = options
      @attrs = HashWithIndifferentAccess.new(initial_attrs)
    end

    def method_missing(method_name, *_args, &_block)
      transform(@attrs).fetch(method_name)
    rescue KeyError
      super
    end

    def respond_to_missing?(method_name, _include_private = false)
      @attrs.key?(method_name)
    end

    def get
      raise NotImplementedError.new, '#get should return a hash of data that represents the remote record.'
    end

    def self.all
      raise NotImplementedError.new, '#all should return an array of hashes of data that represent remote records.'
    end

    def self.where(_params)
      raise NotImplementedError.new, '#where should return an array of hashes of data that represent remote records.'
    end

    def fetch
      @attrs.update(get)
    end

    private

    def transform(data)
      transformers.reduce(data) do |transformed_data, transformer|
        transformer.new(transformed_data).transform
      end
    end

    # Robots in disguise.
    def transformers
      @options.transform.map do |transformer_name|
        "RemoteRecord::Transformers::#{transformer_name.to_s.camelize}".constantize
      end
    end

    def authorization
      authz = @options.authorization
      authz.respond_to?(:call) ? authz.call(@reference, @options) : authz
    end

    def remote_resource_id
      @reference.send(@options.id_field)
    end
  end
end
