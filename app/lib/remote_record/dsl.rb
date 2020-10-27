# frozen_string_literal: true

module RemoteRecord
  # A DSL for constructing RemoteRecords. A basic RemoteRecord could look
  # like this:
  #
  # class UserReference < ApplicationRecord
  # # Reference a RemoteRecord class that defines the necessary methods to fetch
  # # the remote resource using the remote reference.
  #   remote_record { RemoteRecord::GitHub::User }
  # # Supply a means of authorization. This could come from the environment or
  # # be scoped to individual users
  #   remote_authorization { instance.user.github_auth_tokens.active.first.token }
  # end
  module DSL
    def remote_record
      define_method(:remote_record) do |authorization_override = nil|
        instance_exec do
          instance_variable_set('@remote_record',
                                remote_record_klass.new(
                                  remote_resource_id, authorization_override.presence || remote_authorization
                                ))
        end
      end
    end

    # rubocop:disable Naming/PredicateName
    def has_remote(resources, through:)
      define_method(resources) do |authorization_override = nil|
        instance_exec do
          instance_variable_set("@#{resources}", send(through).remote_records(authorization_override))
        end
      end
    end
    # rubocop:enable Naming/PredicateName

    # rubocop:disable Naming/PredicateName
    def has_a_remote(resource, through:)
      define_method(resource) do |authorization_override = nil|
        instance_exec do
          set_instance_variable("@#{resource}", send(through).remote_record(authorization_override))
        end
      end
    end
    # rubocop:enable Naming/PredicateName

    def remote_records(args)
      all.map { |aro| aro.remote_record(args) }
    end
  end
end
