# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. See the project
  # README for more on how to use this.
  module DSL
    extend ActiveSupport::Concern
    class_methods do
      def remote_record(**options)
        klass = KlassLookup.new(self).remote_record_klass(options.to_h[:remote_record_klass])
        config = RemoteRecordConfig.new(remote_record_klass: klass, **options)
        validate_remote_record_config(config)
        define_singleton_method(:config) { RemoteRecordConfig.new(options) }
      end

      private

      def responds_to_get(klass)
        valid = klass.instance_methods(false).include? :get
        return if valid

        raise NotImplementedError.new, 'The remote record does not implement #get.'
      end

      def validate_remote_record_config(options)
        klass = KlassLookup.new(self.class.to_s).remote_record_klass(options.to_h[:remote_record_klass].to_s)
        responds_to_get(klass)
      end
    end
  end
end
