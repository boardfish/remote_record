# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. See the project
  # README for more on how to use this.
  module DSL
    extend ActiveSupport::Concern
    class_methods do
      def remote_record(**options)
        klass = RemoteRecord::ClassLookup.new(self).remote_record_class(options.to_h[:remote_record_class])
        config = RemoteRecord::Config.new(remote_record_class: klass, **options)
        DSLPrivate.validate_config(config)
        define_singleton_method(:config) { RemoteRecord::Config.new(options) }
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
