# frozen_string_literal: true

module RemoteRecord
  # Remote record classes should inherit from this class and define #get.
  class Base
    include ActiveSupport::Rescuable

    def self.inherited(subclass)
      klass = Class.new(RemoteRecord::Type) { @@parent = subclass }
      klass.class_eval do
        def type
          :string
        end

        def cast(remote_resource_id)
          @@parent.new(remote_resource_id)
        end

        def deserialize(value)
          @@parent.new(value)
        end

        def serialize(representation)
          representation
        end
      end
      subclass.const_set :Type, klass
    end

    attr_reader :remote_resource_id

    def initialize(remote_resource_id,
      options = Config.defaults.merge(remote_record_class: self),
      initial_attrs = {}
    )
      @remote_resource_id = remote_resource_id
      @options = options
      @attrs = HashWithIndifferentAccess.new(initial_attrs)
      fetch
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

    def attrs=(new_attrs)
      @attrs.update(new_attrs)
    end

    def fresh
      fetch
      self
    end

    private

    def transform(data)
      return data unless transformers.any?

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
      authz.respond_to?(:call) ? authz.call(@options) : authz
    end
  end
end
