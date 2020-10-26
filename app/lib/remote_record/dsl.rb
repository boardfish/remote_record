# frozen_string_literal: true

module RemoteResource
  # A DSL for constructing RemoteResources. A basic RemoteResource could look
  # like this:
  #
  # include RemoteResource::Plain extend RemoteResource::DSL
  #
  # # Initialize a client that can request the service.
  # client { faraday_json_client('http://example.com') }
  # # Define how you'll fetch a hash of attributes for the resource. Here, we're
  # # requesting example.com?id={id} where {id} is the id of the object.
  # resource { |client, instance| client.get('/', id: instance.id) }
  #
  # # Name an attribute that you'd like to fetch from instances of the remote
  # # resource.
  # remote_attribute :name
  module DSL
    def authorization(mechanism)
      define_method(:authorization) { mechanism.respond_to?(:call) ? mechanism.call : mechanism }
    end

    def remote_attribute(new_getter_name, aliased_field = nil, &block)
      requested_field = aliased_field.presence || new_getter_name
      define_method(new_getter_name.to_sym) do
        block_given? ? block.call(attrs[requested_field]) : attrs[requested_field]
      end
    end

    def attrs(&block)
      define_method(:attrs) do
        raise ArgumentError unless block_given?

        @attrs ||= HashWithIndifferentAccess.new(block.call)
      end
    end
  end
end
