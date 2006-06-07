module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      module UkPhone
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          def has_uk_phone(*attrs)
            require 'ardes/uk_phone'
            config = attrs.last.is_a?(Hash) ? attrs.pop : {}
            attrs = [:phone] if attrs.size == 0
            self.class_eval do
              attrs.each do |attr|
                composed_of attr, :class_name => 'Ardes::UkPhone', :mapping => [attr, :number], :allow_nil => !config[:required]
                validates_part attr
                validates_presence_of attr if config[:required]
              end
            end
          end
        end
      end
    end
  end
end