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
    def remote_authorization(means = nil, &block)
      means = block if block_given?
      @remote_authorization = means
    end

    def remote_record(&block)
      define_method(:remote_record) do
        instance_exec do
          @remote_record ||= block.call.new(remote_resource_id, remote_authorization)
        end
      end
    end

    def remote_records
      all.map(&:remote_record)
    end
  end
end
