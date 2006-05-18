module Ardes
  module Test
    module HasUkPhone
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_has_uk_phone(target_class, *attrs)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_uk_phone_class, :has_uk_phone_attrs
            self.has_uk_phone_class = target_class
            self.has_uk_phone_attrs = attrs
          end
        end
      end

      module InstanceMethods
        def test_has_uk_phone_should_read_phones_as_value_objects
          obj = self.has_uk_phone_class.find_first
          self.has_uk_phone_attrs.each do |attr|
            assert_kind_of Ardes::UkPhone, obj.send(attr) unless obj.send(attr).nil?
          end
        end
        
        def test_has_uk_phone_should_validate_valid_data
          self.has_uk_phone_class.find(:all).each do |record|
            self.has_uk_phone_attrs.each do |attr|
              assert record.valid_for_attributes?(attr)
            end
          end
        end
  
        def test_should_validate_01234567890_on_all_phones
          obj = self.has_uk_phone_class.new
          self.has_uk_phone_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::UkPhone.new('01234567890'))
            assert obj.valid_for_attributes?(attr)
          end
        end
                
        def test_should_invalidate_0123456789_on_all_phones
          obj = self.has_uk_phone_class.new
          self.has_uk_phone_attrs.each do |attr|
            obj.send(attr.to_s + '=', Ardes::UkPhone.new('0123456789'))
            assert(!obj.valid_for_attributes?(attr))
          end
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::HasUkPhone }
