# frozen_string_literal: true

module RemoteRecord
  module TimeKit
    # :nodoc:
    class Base < RemoteRecord::Base
      private

      def client
        APIServices::TimeKit.new
      end
    end
  end
end
