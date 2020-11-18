# frozen_string_literal: true

module RemoteRecord
  # Core structure of a reference. A reference populates itself with all the
  # data for a remote record using behavior defined by its associated remote
  # record class (a descendant of RemoteRecord::Base). This is done on
  # initialize by calling #get on an instance of the remote record class. These
  # attributes are then accessible on the reference thanks to #method_missing.
  module Reference
    extend ActiveSupport::Concern

    class_methods do
      def remote_record_class
        ClassLookup.new(self).remote_record_class(
          remote_record_config.to_h[:remote_record_class]&.to_s
        )
      end

      # Default to an empty config, which falls back to the remote record
      # class's default config and leaves the remote record class to be inferred
      # from the reference class name
      # This method is overridden using RemoteRecord::DSL#remote_record.
      def remote_record_config
        Config.new
      end
    end

    included do
      after_initialize do |reference|
        config = reference.class.remote_record_class.default_config.merge(
          reference.class.remote_record_config.to_h
        )
        reference.instance_variable_set('@remote_record_config', config)
        reference.fetch_remote_resource
      end

      # This doesn't call `super` because it delegates to @instance in all
      # cases.
      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method_name, *_args, &_block)
        fetch_remote_resource unless @remote_record_config.memoize

        @instance.public_send(method_name)
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method_name, _include_private = false)
        instance.respond_to?(method_name, false)
      end

      def initialize(**args)
        @attrs = HashWithIndifferentAccess.new
        super
      end

      def fetch_remote_resource
        instance.fetch
      end

      private

      def instance
        @instance ||= @remote_record_config.remote_record_class.new(self, @remote_record_config)
      end
    end
  end
end
