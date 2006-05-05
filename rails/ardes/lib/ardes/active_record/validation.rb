module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Validation
    
      def self.included(base)
        base.extend(ClassMethods)
        base.send :include, InstanceMethods
      end
    
      module ClassMethods
        
        def validates_uk_phone(*attrs)
          attrs = [:phone] if attrs.empty?
          attrs.each do |a|
            validates_format_of a,
              :with => /^(\+44\s?[1-9]|\(?0[1-9]\)?)(\s?\d\s?){9}$/,
              :message => 'must be a valid UK phone number'
          end
        end
        
        def validates_email(*attrs)
          attrs = [:email] if attrs.empty?
          attrs.each do |a|
            validates_format_of a,
              :with => /^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,9})$/,
              :message => 'must be a valid email address'
          end
        end
        
        def validates_part(*attr_names)
          configuration = {}
          configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)

          validates_each(attr_names, configuration) do |record, attr_name, value|
            dup_value = value.dup
            if !dup_value.valid?
              dup_value.errors.each { |attr, msg| record.errors.add(attr_name, attr.to_s.humanize + " " + msg) }
            end
          end
        end
      end
      
      module InstanceMethods
        # Checks validity on model, then pulls errors for the specified attributes
        def valid_for_attributes?(*attrs)
          attrs = attrs.collect {|attr| attr.to_s}
          unless self.valid?
            errors = self.errors
            our_errors = Array.new
            errors.each { |attr,error|
              if attrs.include? attr
                our_errors << [attr,error]
              end
            }
            errors.clear
            our_errors.each { |attr,error| errors.add(attr,error) }
            return false unless errors.empty?
          end
          return true
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Validation }