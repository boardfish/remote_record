module RemoteRecord
  module Transformers
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
