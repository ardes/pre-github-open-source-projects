module Ardes# :nodoc:
  module ActiveRecord# :nodoc:
    module Has# :nodoc:
      module UkPostcode
        def self.included(base)
          base.extend(ClassMethods)
        end

        module ClassMethods
          def has_uk_postcode(*attrs)
            attrs = [:postcode] if attrs.empty?
            self.class_eval do
              validates_uk_postcode(*attrs)
              before_validation do |record|
                attrs.each do |a|
                  postcode = sanitize_uk_postcode(record.send(a))
                  record.send(a.to_s + '=', postcode)
                end
              end
            end
          end
          
          def validates_uk_postcode(*attrs)
            attrs = [:postcode] if attrs.empty?
            attrs.each do |a|
              validates_format_of a,
                :with => /^((([A-PR-UWYZ])([0-9][0-9A-HJKS-UW]?))|(([A-PR-UWYZ][A-HK-Y])([0-9][0-9ABEHMNPRV-Y]?))\s{0,2}(([0-9])([ABD-HJLNP-UW-Z])([ABD-HJLNP-UW-Z])))|(((GI)(R))\s{0,2}((0)(A)(A)))$/i,
                :message => 'must be a valid UK postcode'
            end
          end
          
          def sanitize_uk_postcode(postcode)
            postcode.upcase
          end
        end
      end
    end
  end
end

ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::UkPostcode }

