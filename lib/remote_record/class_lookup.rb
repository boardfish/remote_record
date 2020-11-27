# frozen_string_literal: true

module RemoteRecord
  # Looks up the class name to use to define the remote record's behavior.
  class ClassLookup
    def initialize(klass)
      @klass = klass
    end

    def remote_record_class(class_name_override = nil)
      class_name = (class_name_override || infer_remote_record_class_name)
      class_name.constantize
    rescue NameError
      raise RemoteRecord::RecordClassNotFound, "#{class_name} couldn't be found." \
      "#{' Perhaps you need to define `remote_record_class`?' unless class_name_override}"
    end

    private

    def infer_remote_record_class_name
      "RemoteRecord::#{@klass.to_s.delete_suffix('Reference')}"
    end
  end
end
