module RemoteRecord
  class Type < ActiveRecord::Type::Value
    def type
      raise 'type not defined'
    end

    def cast(remote_resource_id)
      raise 'cast not defined'
    end

    def deserialize(value)
      raise 'deserialize not defined'
    end

    def serialize(remote_resource_representation)
      raise 'serialize not defined'
    end
  end
end
