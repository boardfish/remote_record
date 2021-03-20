# frozen_string_literal: true

module RemoteRecord
  # Core structure of a reference. A reference populates itself with all the
  # data for a remote record using behavior defined by its associated remote
  # record class (a descendant of RemoteRecord::Base). This is done on
  # initialize by calling #get on an instance of the remote record class. These
  # attributes are then accessible on the reference thanks to #method_missing.
  module Reference # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern

    class_methods do # rubocop:disable Metrics/BlockLength
      attr_accessor :fetching

      def remote_record_class
        ClassLookup.new(self).remote_record_class(
          remote_record_config.to_h[:remote_record_class]&.to_s
        )
      end

      # Default to an empty config, which falls back to the remote record
      # class's default config and leaves the remote record class to be inferred
      # from the reference class name
      # This method is overridden using RemoteRecord::DSL#remote_record.
      def remote_record_config
        Config.new
      end

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

      def remote_all(&authz_proc)
        find_or_initialize_all(remote_record_class.all(&authz_proc))
      end

      def remote_where(params, &authz_proc)
        find_or_initialize_all(remote_record_class.where(params, &authz_proc))
      end

      def remote_find_by(params, &authz_proc)
        return remote_where(params, &authz_proc).first unless remote_record_class.respond_to?(:find_by)

        resource = remote_record_class.find_by(params, &authz_proc)
        new(remote_resource_id: resource['id'], initial_attrs: resource)
      end

      def remote_find_or_initialize_by(params, &authz_proc)
        return remote_where(params, &authz_proc).first unless remote_record_class.respond_to?(:find_by)

        resource = remote_record_class.find_by(params, &authz_proc)
        find_or_initialize_one(id: resource['id'], initial_attrs: resource)
      end

      private

      def find_or_initialize_one(id:, initial_attrs:)
        existing_record = no_fetching { find_by(remote_resource_id: id) }
        return existing_record.tap { |r| r.attrs = initial_attrs } if existing_record.present?

        new(remote_resource_id: id, initial_attrs: initial_attrs)
      end

      def find_or_initialize_all(remote_resources)
        no_fetching do
          pair_remote_resources_with_records(remote_resources) do |unsaved_resources, relation|
            new_resources = unsaved_resources.map do |resource|
              new(remote_resource_id: resource['id']).tap { |record| record.attrs = resource }
            end
            relation.to_a + new_resources
          end
        end
      end

      def pair_remote_resources_with_records(remote_resources)
        # get resource ids
        ids = remote_resource_ids(remote_resources)
        # get what exists in the database
        relation = where(remote_resource_id: ids)
        # for each record, set its attrs
        relation.map do |record|
          record.attrs = remote_resources.find do |r|
            r['id'].to_s == record.remote_resource_id.to_s
          end
        end
        unsaved_resources = resources_without_persisted_references(remote_resources, relation)
        yield(unsaved_resources, relation)
      end

      def remote_resource_ids(remote_resources)
        remote_resources.map { |remote_resource| remote_resource['id'] }
      end

      def resources_without_persisted_references(remote_resources, relation)
        remote_resources.reject do |resource|
          relation.pluck(:remote_resource_id).include? resource['id']
        end
      end
    end

    # rubocop:disable Metrics/BlockLength
    included do
      include ActiveSupport::Rescuable

      def remote
        remote_resource_id
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
