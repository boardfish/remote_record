# frozen_string_literal: true

module RemoteRecord
  # RemoteRecord uses the Active Record Types system to serialize to and from a
  # remote resource.
  class Type < ActiveRecord::Type::Value
    def type
      raise 'type not defined'
    end

    def cast(_remote_resource_id)
      raise 'cast not defined'
    end

    def deserialize(_value)
      raise 'deserialize not defined'
    end

    def serialize(_remote_resource_representation)
      raise 'serialize not defined'
    end
  end
end
