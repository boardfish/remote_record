# frozen_string_literal: true

module RemoteRecord
  module Transformers
    # Converts keys to snake case.
    class DotParams < RemoteRecord::Transformers::Base
      def transform
        convert_hash_keys(@data).map { |k, v| "#{CGI.escape(k.to_s)}:#{CGI.escape(v.to_s)}" }.join(';')
      end

      private

      def convert_hash_keys(data)
        data.each_with_object({}) do |(k, v), h|
          if v.is_a? Hash
            convert_hash_keys(v).map do |h_k, h_v|
              h["#{k}.#{h_k}".to_sym] = h_v
            end
          else
            h[k] = v
          end
        end
      end
    end
  end
end
