# frozen_string_literal: true

module RemoteRecord
  module Transformers
    # Converts keys to snake case.
    class SnakeCase < RemoteRecord::Transformers::Base
      def transform
        convert_hash_keys(@data)
      end

      private

      def convert_hash_keys(value)
        case value
        when Array
          value.map { |v| convert_hash_keys(v) }
        when Hash
          Hash[value.map { |k, v| [underscore_key(k), convert_hash_keys(v)] }]
        else
          value
        end
      end

      def underscore_key(key)
        key.to_s.underscore.to_sym
      end
    end
  end
end
