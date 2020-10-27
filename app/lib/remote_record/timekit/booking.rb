# frozen_string_literal: true

module RemoteRecord
  module TimeKit
    # :nodoc:
    class Booking
      include RemoteRecord::Core
      extend  RemoteRecord::DSL

      private

      def client
        APIServices::TimeKit.new
      end

      def get
        client.booking(id)
      end
    end
  end
end
