# frozen_string_literal: true

module RemoteRecord
  # A DSL that's helpful for configuring remote references. See the project
  # README for more on how to use this.
  module DSL
    def remote_record(**options)
      validate_remote_record_config(options)
      define_method(:remote_record_config) { options }
    end

    private

    def responds_to_get(klass)
      valid = klass.instance_methods(false).include? :get
      return if valid

      raise NotImplementedError.new, 'The remote record does not implement #get.'
    end

    def validate_remote_record_config(options)
      klass = KlassLookup.new(self).remote_record_klass(options[:remote_record_klass])
      responds_to_get(klass)
    end
  end
end
