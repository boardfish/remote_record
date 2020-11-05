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

    def remote_record_class(new_value = nil, &block)
      return @options.fetch(__method__) unless block_given? || new_value

      @options[__method__] = block || new_value
      self
    end

    def authorization(new_value = nil, &block)
      return @options.fetch(__method__) unless block_given? || new_value

      @options[__method__] = block || new_value
      self
    end

    def caching(new_value = nil, &block)
      return @options.fetch(__method__) unless block_given? || new_value

      @options[__method__] = block || new_value
      self
    end

    def id_field(new_value = nil, &block)
      return @options.fetch(__method__) unless block_given? || new_value

      @options[__method__] = block || new_value
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
