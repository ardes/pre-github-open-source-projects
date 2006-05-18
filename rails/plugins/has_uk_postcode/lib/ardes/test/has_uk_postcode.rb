module Ardes
  module Test
    module HasUkPostcode
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_has_uk_postcode(target_class, *postcode_attributes)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_uk_postcode_class, :has_uk_postcode_attrs
            self.has_uk_postcode_class = target_class
            self.has_uk_postcode_attrs = postcode_attributes
          end
        end
      end

      module InstanceMethods
        def test_has_uk_postcode_should_read_postcodes_as_value_objects
          obj = self.has_uk_postcode_class.find_first
          self.has_uk_postcode_attrs.each do |attr|
            assert_kind_of Ardes::UkPostcode, obj.send(attr) unless obj.send(attr).nil?
          end
        end
      
        def test_has_uk_postcode_should_validate_valid_data
          self.has_uk_postcode_class.find(:all).each do |record|
            self.has_uk_postcode_attrs.each do |attr|
              assert record.valid_for_attributes?(attr)
            end
          end
        end

        def test_should_validate_S11_8BH_on_all_postcodes
          obj = self.has_uk_postcode_class.new
          self.has_uk_postcode_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::UkPostcode.new('S11 8BH'))
            assert obj.valid_for_attributes?(attr)
          end
        end
              
        def test_should_validate_XXX_XXX_on_all_postcodes
          obj = self.has_uk_postcode_class.new
          self.has_uk_postcode_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::UkPostcode.new('XXX XXX'))
            assert(!obj.valid_for_attributes?(attr))
          end        
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::HasUkPostcode }