# frozen_string_literal: true

module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::GitHub::Base
      def get
        client.user(remote_resource_id)
      end
    end
  end
end
