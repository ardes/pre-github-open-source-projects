module ActiveRecord# :nodoc:
  module Has# :nodoc:
    module UkPostcode
      def has_uk_postcode(*attrs)
        require 'uk_postcode'
        config = attrs.last.is_a?(Hash) ? attrs.pop : {}
        attrs = [:postcode] if attrs.size == 0
        self.class_eval do
          attrs.each do |attr|
            composed_of attr, :class_name => 'UkPostcode', :mapping => [attr, :code]
            validates_part attr, :if => attr
            validates_presence_of attr if config[:required]
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { extend ActiveRecord::Has::UkPostcode }