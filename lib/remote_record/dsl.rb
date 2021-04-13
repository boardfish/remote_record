# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. To configure a
  # remote reference, `include RemoteRecord`, then call `remote_record` to
  # configure the module.
  # See RemoteRecord::Config#defaults for the default configuration.
  module DSL
    extend ActiveSupport::Concern
    class_methods do
      def remote_record(remote_record_class: nil, field: :remote_resource_id)
        klass = DSLPrivate.lookup_and_validate_class(self, remote_record_class)
        base_config = RemoteRecord::Config.defaults
        base_config = yield(base_config) if block_given?
        # Register the field as an Active Record attribute of the remote record
        # class's type
        attribute field, klass::Type[base_config].new

        DSLPrivate.define_remote_scope(self, klass, field)
        DSLPrivate.define_remote_accessor(self, field)
      end
    end
  end

  # Methods private to the DSL module.
  module DSLPrivate
    class << self
      def lookup_and_validate_class(klass, override)
        RemoteRecord::ClassLookup.new(klass).remote_record_class(override).tap do |found_klass|
          validate_responds_to_get(found_klass)
        end
      end

      # Define the #remote scope, which returns a Collection for the given
      # Remote Record class
      def define_remote_scope(base, klass, field_name)
        base.define_singleton_method(:remote) do |id_field = field_name, config: nil|
          klass::Collection.new(all, config, id: id_field)
        end
      end

      # Define the #remote accessor for instances - this uses the Active
      # Record type, but adds a reference to the parent object into the config
      # to be used in authorization.
      def define_remote_accessor(base, field_name)
        base.define_method(:remote) do |id_field = field_name|
          self[id_field].tap { |record| record.remote_record_config.merge!(authorization_source: self) }
        end
      end

      def validate_responds_to_get(klass)
        raise NotImplementedError.new, 'The remote record does not implement #get.' unless responds_to_get?(klass)
      end

      def responds_to_get?(klass)
        klass.instance_methods(false).include? :get
      end
    end
  end
end
