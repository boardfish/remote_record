# frozen_string_literal: true

module RemoteRecord
  module Transformers
    # Base transformer class. Inherit from this and implement `#transform`.
    class Base
      def initialize(data, direction = :up)
        raise ArgumentError.new('The direction should be one of :up or :down.') unless [:up, :down].include? direction
        @data = data
        @direction = direction
      end

      def transform
        raise NotImplementedError
      end
    end
  end
end
