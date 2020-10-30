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

    def remote_record_klass(option_override = nil)
      klass_name = (option_override || infer_remote_record_class_name)
      klass_name.constantize
    rescue NameError
      raise RemoteRecord::RecordClassNotFound, "#{klass_name} couldn't be found." \
      "#{' Perhaps you need to define remote_record_klass?' unless option_override}"
    end

    def responds_to_get(klass)
      valid = klass.instance_methods(false).include? :get
      return if valid

      raise NotImplementedError.new, 'The remote record does not implement #get.'
    end

    def validate_remote_record_config(options)
      klass = remote_record_klass(options[:remote_record_klass])
      responds_to_get(klass)
    end

    def infer_remote_record_class_name
      # byebug
      "RemoteRecord::#{to_s.delete_suffix('Reference')}"
    end
  end
end
