# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. To configure a
  # remote reference, `include RemoteRecord`, then call `remote_record` to
  # configure the module.
  # See RemoteRecord::Config#defaults for the default configuration.
  module DSL
    extend ActiveSupport::Concern
    class_methods do
      def remote_record(remote_record_class: nil)
        klass = RemoteRecord::ClassLookup.new(self).remote_record_class(remote_record_class)
        config = RemoteRecord::Config.new(remote_record_class: klass)
        config = yield(config) if block_given?
        DSLPrivate.validate_config(config)
        define_singleton_method(:remote_record_config) { config }
      end
    end
  end

  # Methods private to the DSL module.
  module DSLPrivate
    class << self
      def responds_to_get?(klass)
        klass.instance_methods(false).include? :get
      end

      def validate_config(options)
        klass = RemoteRecord::ClassLookup.new(self.class.to_s)
                                         .remote_record_class(options.to_h[:remote_record_class].to_s)
        raise NotImplementedError.new, 'The remote record does not implement #get.' unless responds_to_get?(klass)
      end
    end
  end
end
