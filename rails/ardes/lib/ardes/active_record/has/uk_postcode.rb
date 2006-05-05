module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      module UkPostcode
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_uk_postcode(*attrs)
            require 'ardes/value_objects/uk_postcode'
            attrs = [:postcode] if attrs.empty?
            self.class_eval do
              attrs.each do |attr|
                composed_of attr, :class_name => 'UkPostcode', :mapping => [attr, :code]
                validates_part attr
              end
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::UkPostcode }

