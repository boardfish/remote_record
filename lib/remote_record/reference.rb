# frozen_string_literal: true

module RemoteRecord
  # Core structure of a reference. A reference populates itself with all the
  # data for a remote record using behavior defined by its associated remote
  # record class (a descendant of RemoteRecord::Base). This is done on
  # initialize by calling #get on an instance of the remote record class. These
  # attributes are then accessible on the reference thanks to #method_missing.
  module Reference
    extend ActiveSupport::Concern

    class_methods do
      attr_accessor :fetching

      def fetching
        @fetching = true if @fetching.nil?
        @fetching
      end

      # Disable fetching for all records initialized in the block.
      def no_fetching
        self.fetching = false
        block_return_value = yield(self)
        self.fetching = true
        block_return_value
      end

      def remote(id_field = :remote_resource_id, config: nil)
        RemoteRecord::Collection.new(all, config, id: id_field)
      end
    end

    included do
      include ActiveSupport::Rescuable

      def remote
        remote_resource_id
      end
    end
  end
end
