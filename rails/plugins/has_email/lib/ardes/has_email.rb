module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      module Email
        def self.included(base)
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          def has_email(*attrs)
            require 'ardes/email'
            config = attrs.last.is_a?(Hash) ? attrs.pop : {}
            attrs = [:email] if attrs.size == 0
            self.class_eval do
              attrs.each do |attr|
                composed_of attr, :class_name => 'Ardes::Email', :mapping => [attr, :address], :allow_nil => !config[:required]
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