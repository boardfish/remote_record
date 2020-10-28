# frozen_string_literal: true

module RemoteRecord
  module GitHub
    # :nodoc:
    class User
      include RemoteRecord::Core

      private

      def client
        Octokit::Client.new(access_token: authorization)
      end

      def get
        client.user(id.to_i)
      end
    end
  end
end
