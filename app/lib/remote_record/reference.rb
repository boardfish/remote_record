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

    included do
      after_initialize do |reference|
        remote_record_klass = KlassLookup.new(reference.class).remote_record_klass(
          remote_record_config[:remote_record_klass]
        )
        config = remote_record_klass.config
                                    .merge(klass: remote_record_klass, id_field: :remote_record_id)
                                    .merge(remote_record_config)
        reference.instance_variable_set('@remote_record_options', config)
        reference.fetch_attributes
      end
    end

    def method_missing(method_name, *_args, &_block)
      fetch_attributes unless @remote_record_options.fetch(:caching)
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

    def fetch_attributes
      @attrs = HashWithIndifferentAccess.new(
        @remote_record_options.fetch(:klass).new(self, @remote_record_options).get
      )
    end
  end
end
