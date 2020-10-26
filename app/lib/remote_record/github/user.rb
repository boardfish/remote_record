module RemoteRecord
  module GitHub
    module User
      include RemoteRecord::Core
      extend RemoteRecord::DSL

      attrs { client.user(remote_resource_id) }

      private

      def client
        APIServices::GitHub.new(authorization)
      end
    end
  end
end
