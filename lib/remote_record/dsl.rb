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
        klass = RemoteRecord::ClassLookup.new(self).remote_record_class(remote_record_class)
        base_config = RemoteRecord::Config.new(remote_record_class: klass)
        base_config = yield(base_config) if block_given?
        DSLPrivate.validate_config(base_config)
        attribute field, klass::Type[base_config].new
        define_singleton_method(:remote) do |id_field = field, config: nil|
          klass::Collection.new(all, config, id: id_field)
        end
        define_method(:remote) { |id_field = field| self[id_field].tap { |record| record.remote_record_config.merge!(authorization_source: self) } }
      end
    end
  end

  # Methods private to the DSL module.
  module DSLPrivate
    class << self
      def responds_to_get?(klass)
        klass.instance_methods(false).include? :get
      end

      def validate_config(config)
        klass = RemoteRecord::ClassLookup.new(self.class.to_s)
                                         .remote_record_class(config.to_h[:remote_record_class].to_s)
        raise NotImplementedError.new, 'The remote record does not implement #get.' unless responds_to_get?(klass)
      end
    end
  end
end
