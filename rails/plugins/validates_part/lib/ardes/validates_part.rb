module Ardes
  module ActiveRecord
    module ValidatesPart
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # validates a model part (an aggregation, or association) storing the error messages under the name of the part
        def validates_part(*attr_names)
          configuration = {}
          configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

          validates_each(attr_names, configuration) do |record, attr_name, value|
            if value
              dup_value = value.dup
              if !dup_value.valid?
                dup_value.errors.each { |attr, msg| record.errors.add(attr_name, attr.to_s.humanize + " " + msg) }
              end
            end
          end
        end
      end
    end
  end
end