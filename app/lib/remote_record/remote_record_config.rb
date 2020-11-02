# frozen_string_literal: true

# Configuration specific to a single remote record, hence the duplicate name. If
# this were global config for the whole module, it'd be at RemoteRecord::Config.
module RemoteRecord
  # Configuration propagated between remote records and their references. When a
  # new remote reference is initialized, its config is constructed using the
  # defaults of the remote record class and the overrides set when
  # `remote_record` is called.
  class RemoteRecordConfig
    def initialize(**options)
      @options = {
        authorization: proc {},
        caching: false,
        id_field: :remote_resource_id
      }.merge(options)
    end

    def remote_record_klass
      @options.fetch(:remote_record_klass)
    end

    def authorization
      @options.fetch(:authorization)
    end

    def caching
      @options.fetch(:caching)
    end

    def id_field
      @options.fetch(:id_field)
    end

    def to_h
      @options
    end

    def merge(**overrides)
      @options.merge!(**overrides)
      self
    end
  end
end
