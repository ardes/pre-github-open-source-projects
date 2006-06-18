module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      module UkPostcode
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          def has_uk_postcode(*attrs)
            require 'ardes/uk_postcode'
            config = attrs.last.is_a?(Hash) ? attrs.pop : {}
            attrs = [:postcode] if attrs.size == 0
            self.class_eval do
              attrs.each do |attr|
                composed_of attr, :class_name => 'Ardes::UkPostcode', :mapping => [attr, :code], :allow_nil => !config[:required]
                validates_part attr, :prepend_attribute => false
                validates_presence_of attr if config[:required]
              end
            end
          end
        end
      end
    end
  end
end