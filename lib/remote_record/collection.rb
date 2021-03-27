# frozen_string_literal: true

module RemoteRecord
  # Wraps operations on collections of remote references. By calling #remote on
  # on an ActiveRecord relation, you'll get a RemoteRecord::Collection you can
  # use to more easily fetch multiple records at once.
  #
  # The default implementation is naive and sends a request per object.
  class Collection
    delegate :length, to: :@relation

    def initialize(active_record_relation, config = nil, id: :remote_resource_id)
      @relation = active_record_relation
      @config = config
      @id_field = id
    end

    def all
      fetch_all_scoped_records(@relation)
    end

    private

    # Override this to define more succinct ways to request all records at once.
    # If your API has a search endpoint, you may want to use that. Otherwise,
    # list all objects and leave it to Remote Record to pick out the ones you
    # have in your database.
    def fetch_all_scoped_records(relation)
      relation.map do |record|
        record.remote.remote_record_config.merge(@config)
        record.tap { |r| r.remote.fresh }
      end
    end
  end
end
