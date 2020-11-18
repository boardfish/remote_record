# frozen_string_literal: true

module RemoteRecord
  module TimeKit
    # :nodoc:
    class Booking < RemoteRecord::TimeKit::Base
      def get
        client.booking(remote_resource_id)
      end
    end
  end
end
