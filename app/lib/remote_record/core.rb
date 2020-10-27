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
  module Core
    attr_reader :id

    # Allows top-level attributes of the remote record to be accessed using dot
    # notation.
    def method_missing(method_name, *_args, &_block)
      refresh_internal_state unless @opts[:caching]
      return super unless @attrs.key?(method_name)

      @attrs.fetch(method_name)
    end

    def respond_to_missing?(method_name, _include_private = false)
      @attrs.key?(method_name)
    end

    # Initializes the record and fetches its remote representation.
    def initialize(id, authorization, opts: {})
      @opts = option_defaults.merge(opts)
      @id = id
      @authorization = authorization
      refresh_internal_state
    end

    private

    # Fetches the record's remote representation and stores it in the class.
    # method_missing makes top-level attributes accessible on the model directly
    # via methods.
    def refresh_internal_state
      @attrs = HashWithIndifferentAccess.new(get)
    end

    def authorization
      @authorization.respond_to?(:call) ? @authorization.call : @authorization
    end

    def option_defaults
      { caching: false }
    end
  end
end
