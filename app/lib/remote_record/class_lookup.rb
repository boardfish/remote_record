# frozen_string_literal: true

module RemoteRecord
  # Looks up the class name to use to define the remote record's behavior.
  class ClassLookup
    def initialize(klass)
      @klass = klass
    end

    def remote_record_klass(klass_name_override = nil)
      klass_name = (klass_name_override || infer_remote_record_class_name)
      klass_name.constantize
    rescue NameError
      raise RemoteRecord::RecordClassNotFound, "#{klass_name} couldn't be found." \
      "#{' Perhaps you need to define remote_record_klass?' unless klass_name_override}"
    end

    private

    def infer_remote_record_class_name
      # byebug
      "RemoteRecord::#{@klass.to_s.delete_suffix('Reference')}"
    end
  end
end
