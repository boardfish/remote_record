# frozen_string_literal: true

module RemoteRecord
  module TimeKit
    # :nodoc:
    class Booking < RemoteRecord::TimeKit::Base
      def get
        resource client.booking(remote_resource_id)
      end
    end
  end
end
