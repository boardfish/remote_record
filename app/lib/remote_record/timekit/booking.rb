# frozen_string_literal: true

module RemoteRecord
  module TimeKit
    # :nodoc:
    class Booking < RemoteRecord::Base
      def get
        client.booking(remote_resource_id)
      end

      private

      def client
        APIServices::TimeKit.new
      end
    end
  end
end
