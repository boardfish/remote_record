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
    # Allows top-level attributes of the remote record to be accessed using dot
    # notation.
    def self.included(record_type)
      super
      remote_record_klass = lookup_remote_record_class('RemoteRecord', record_type.to_s.delete_suffix('Reference'))
      raise 'get not defined' unless remote_record_klass.instance_methods(false).include?(:get)

      record_type.belongs_to :user
      record_type.validates  :remote_resource_id, presence: true
      # rubocop:disable Style/SymbolProc
      record_type.after_initialize do |reference|
        reference.fetch_attributes
      end
      # rubocop:enable Style/SymbolProc
    end

    def self.lookup_remote_record_class(*args)
      args.join('::').constantize
    rescue NameError
      raise "Class #{args.join('::')} does not exist. Perhaps you need to specify the remote_record_klass option?"
    end

    def lookup_remote_record_class(*args)
      args.join('::').constantize
    rescue NameError
      raise "Class #{args.join('::')} does not exist. Perhaps you need to specify the remote_record_klass option?"
    end

    attr_reader :remote_record_options

    def method_missing(method_name, *_args, &_block)
      fetch_attributes unless remote_record_options.fetch(:caching)
      return super unless @attrs.key?(method_name)

      @attrs.fetch(method_name)
    end

    def respond_to_missing?(method_name, _include_private = false)
      @attrs.key?(method_name)
    end

    def initialize(**args)
      @attrs = HashWithIndifferentAccess.new
      remote_record_klass = lookup_remote_record_class('RemoteRecord', self.class.to_s.delete_suffix('Reference'))
      @remote_record_options = remote_record_klass.config
                                                  .merge(klass: remote_record_klass, id_field: :remote_record_id)
                                                  .merge(remote_record_config)
      super
    end

    def fetch_attributes
      @attrs = HashWithIndifferentAccess.new(
        remote_record_options.fetch(:klass).new(self, @remote_record_options).get
      )
    end
  end
end
