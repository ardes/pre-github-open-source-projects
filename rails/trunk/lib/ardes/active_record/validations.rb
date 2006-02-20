module Ardes
  module ActiveRecord
    module Validations
    
      def self.included(mod)
        mod.extend(ClassMethods)
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
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Validations }