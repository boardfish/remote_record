# frozen_string_literal: true

module RemoteRecord
  # RemoteRecord uses the Active Record Types system to serialize to and from a
  # remote resource.
  class Type < ActiveRecord::Type::Value
    def type
      :string
    end

    def cast(_remote_resource_id)
      raise 'cast not defined'
    end

    def deserialize(value)
      cast(value)
    end

    def serialize(representation)
      return representation.remote_resource_id if representation.respond_to? :remote_resource_id

      representation.to_s
    end
  end
end
