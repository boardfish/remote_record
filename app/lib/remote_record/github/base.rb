# frozen_string_literal: true

module RemoteRecord
  module GitHub
    # Defines the client that is used to fetch remote records from GitHub.
    class Base < RemoteRecord::Base
      private

      def client
        Octokit::Client.new(access_token: authorization)
      end
    end
  end
end
