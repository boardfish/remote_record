# frozen_string_literal: true

module RemoteRecord
  module Transformers
    # Base transformer class. Inherit from this and implement `#transform`.
    class Base
      def initialize(data)
        @data = data
      end

      def transform
        raise NotImplementedError
      end
    end
  end
end
