# frozen_string_literal: true

module RemoteRecord
  # Core structure of a RemoteRecord. In order to use this, include
  # RemoteRecord::Core in a class, then define the :get method on instances of
  # that class. It's also recommended to specify a method on the class that
  # defines a client, then use this client in your get method.
  # Example:
  # class User
  #   include RemoteRecord::Core

  #   private

  #   def client
  #     Octokit::Client.new(access_token: authorization)
  #   end

  #   def get
  #     client.user(id)
  #   end
  # end
  module Reference
    extend ActiveSupport::Concern

    class_methods do
      def remote_record_class
        ClassLookup.new(self).remote_record_class(
          remote_record_config.to_h[:remote_record_class]
        )
      end
    end
    included do
      after_initialize do |reference|
        config = reference.class.remote_record_class.default_config.merge(reference.class.remote_record_config)
        reference.instance_variable_set('@remote_record_options', config)
        reference.fetch_remote_resource
      end

      def method_missing(method_name, *_args, &_block)
        fetch_remote_resource unless @remote_record_options.caching
        return super unless @attrs.key?(method_name)

        @attrs.fetch(method_name)
      end

      def respond_to_missing?(method_name, _include_private = false)
        @attrs.key?(method_name)
      end

      def initialize(**args)
        @attrs = HashWithIndifferentAccess.new
        super
      end

      def fetch_remote_resource
        @attrs = HashWithIndifferentAccess.new(instance.get)
      end

      private

      def instance
        @remote_record_options.remote_record_class.new(self, @remote_record_options)
      end
    end
  end
end
