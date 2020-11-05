# frozen_string_literal: true

# Configuration specific to a single remote record class.
module RemoteRecord
  # Configuration propagated between remote records and their references. When a
  # new remote reference is initialized, its config is constructed using the
  # defaults of the remote record class and the overrides set when
  # `remote_record` is called.
  class Config
    def initialize(**options)
      @options = options
    end

    def self.defaults
      new(
        authorization: proc {},
        caching: true,
        id_field: :remote_resource_id
      )
    end

    %i[remote_record_class authorization caching id_field].each do |option|
      define_method(option) do |new_value = nil, &block|
        block_attr_accessor(option, new_value, &block)
      end
    end

    # Returns the attribute value if called without args or a block. Otherwise,
    # sets the attribute to the block or value passed.
    def block_attr_accessor(attribute, new_value = nil, &block)
      return @options.fetch(attribute) unless block_given? || new_value

      @options[attribute] = block || new_value
      self
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
