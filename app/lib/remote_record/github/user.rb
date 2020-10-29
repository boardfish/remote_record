# frozen_string_literal: true

module RemoteRecord
  module GitHub
    # :nodoc:
    class User < RemoteRecord::Base
      def get
        client.user(remote_resource_id)
      end

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
