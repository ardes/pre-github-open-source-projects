module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Validations
    
      def self.included(base)
        base.extend(ClassMethods)
        base.send :include, InstanceMethods
      end
    
      module ClassMethods
        def validates_handle(*attributes)
          attributes = [:handle] if attributes.empty?
          attributes.each do |a|
            validates_presence_of a
            validates_uniqueness_of a
            validates_length_of a, :maximum => 50
            validates_format_of a, :with => /^[a-z_][a-z_]*$/,
              :message => "must contain only lowercase letters and underscore"
          end
        end
      end
      
      module InstanceMethods
        def valid_for_attributes(*attributes)
          unless self.valid?
            errors = self.errors
            our_errors = Array.new
            errors.each { |attr,error|
              if attributes.include? attr
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

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Validations }