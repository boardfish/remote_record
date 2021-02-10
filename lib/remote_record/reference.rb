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
      attr_accessor :fetching

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

      def fetching
        @fetching = true if @fetching.nil?
        @fetching
      end

      # Disable fetching for all records initialized in the block.
      def no_fetching
        self.fetching = false
        block_return_value = yield(self)
        self.fetching = true
        block_return_value
      end

      def remote_all(&authz_proc)
        remote_record_class.all(&authz_proc).map do |remote_resource|
          where(remote_resource_id: remote_resource['id']).first_or_initialize(initial_attrs: remote_resource)
        end
      end

      def remote_where(params, &authz_proc)
        remote_record_class.where(params, &authz_proc).map do |remote_resource|
          where(remote_resource_id: remote_resource['id']).first_or_initialize(initial_attrs: remote_resource)
        end
      end
    end

    # rubocop:disable Metrics/BlockLength
    included do
      include ActiveSupport::Rescuable
      attribute :fetching, :boolean, default: -> { self.fetching }
      attr_accessor :initial_attrs

      after_initialize do |reference|
        reference.fetching = false if reference.initial_attrs.present?
        config = reference.class.remote_record_class.default_config.merge(
          reference.class.remote_record_config.to_h
        )
        reference.instance_variable_set('@remote_record_config', config)
        reference.instance_variable_set('@instance',
                                        @remote_record_config.remote_record_class.new(
                                          self, @remote_record_config, reference.initial_attrs.presence || {}
                                        ))
        reference.fetch_remote_resource
      end

      # This doesn't call `super` because it delegates to @instance in all
      # cases.
      def method_missing(method_name, *_args, &_block)
        fetch_remote_resource unless @remote_record_config.memoize

        instance.public_send(method_name)
      end

      def respond_to_missing?(method_name, _include_private = false)
        instance.respond_to?(method_name, false)
      end

      def fetch_remote_resource
        instance.fetch if fetching
      rescue Exception => e # rubocop:disable Lint/RescueException
        rescue_with_handler(e) || raise
      end

      def fresh
        instance.fetch
        self
      end

      private

      def instance
        @instance ||= @remote_record_config.remote_record_class.new(self, @remote_record_config)
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
