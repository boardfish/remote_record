# frozen_string_literal: true

module RemoteRecord
  # Remote record classes should inherit from this class and define #get.
  class Base
    include ActiveSupport::Rescuable

    # rubocop:disable Style/ClassVars
    # rubocop:disable Metrics/AbcSize
    # When you inherit from `Base`, it'll set up an Active Record Type for you
    # available on its Type constant. It'll also have a Collection.
    def self.inherited(subclass) # rubocop:disable Metrics/MethodLength
      # Active Record Type setup
      klass = Class.new(RemoteRecord::Type) do |type|
        type.parent = subclass
        def self.[](config_override)
          Class.new(self).tap do |configured_type|
            configured_type.config = config_override
          end
        end

        def cast(remote_resource_id)
          return remote_resource_id if remote_resource_id.is_a?(parent)

          parent.new(remote_resource_id, self.config)
        end
      end
      subclass.const_set :Type, klass
      subclass.const_set :Collection, Class.new(RemoteRecord::Collection) unless subclass.const_defined? :Collection
      super
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Style/ClassVars

    attr_reader :remote_resource_id
    attr_accessor :remote_record_config

    def initialize(remote_resource_id,
                   remote_record_config = Config.defaults,
                   initial_attrs = {})
      @remote_resource_id = remote_resource_id
      @remote_record_config = remote_record_config
      @attrs = HashWithIndifferentAccess.new(initial_attrs)
      @fetched = initial_attrs.present?
    end

    def method_missing(method_name, *_args, &_block)
      fetch unless @remote_record_config.memoize && @fetched
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

    def fetch
      @attrs.update(get)
      @fetched = true
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
      @remote_record_config.transform.map do |transformer_name|
        "RemoteRecord::Transformers::#{transformer_name.to_s.camelize}".constantize
      end
    end

    def authorization
      authz = @remote_record_config.authorization
      authz.respond_to?(:call) ? authz.call(@remote_record_config.authorization_source) : authz
    end
  end
end
