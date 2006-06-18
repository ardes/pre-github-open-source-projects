module Ardes
  module ActiveRecord
    module ValidatesPart
      def self.included(base)
        base.extend(ClassMethods)
      end
      
      module ClassMethods
        # validates a model part (an aggregation, or association) storing the error messages under the name of the part
        # takes :prepend_attribute => true/false as an option (defaults to true)
        def validates_part(*attr_names)
          configuration = {}
          configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
          
          prepend_attribute = true if (prepend_attribute = configuration.delete(:prepend_attribute)).nil?

          validates_each(attr_names, configuration) do |record, attr_name, value|
            if value
              dup_value = value.dup
              if !dup_value.valid?
                dup_value.errors.each do |attr, msg|
                  prepend = prepend_attribute ? attr.to_s.humanize.downcase + ' ' : ''
                  record.errors.add(attr_name, "#{prepend}#{msg}")
                end
              end
            end
          end
        end
      end
    end
  end
end