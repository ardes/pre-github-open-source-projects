module Ardes
  module Test
    module HasUkPhone
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Usage: 
        #   test_has_uk_phone Class, :phone_attr
        #   test_has_uk_phone Class, :phone_attr, :another_phone_attr
        #   test_has_uk_phone Class, :phone_attr, ..., [fixture names]
        #
        # If fixture names are given then those fixtures will be tested,
        # if ommitted then all fixtures will be tested
        def test_has_uk_phone(target_class, *args)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_uk_phone_class, :has_uk_phone_attrs, :has_uk_phone_fixtures
            self.has_uk_phone_fixtures = args.last.is_a?(Array) ? args.pop : nil
            self.has_uk_phone_class = target_class
            self.has_uk_phone_attrs = args
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
        
        def test_has_uk_phone_should_validate_valid_data_in_fixtures
          if self.has_uk_phone_fixtures
            to_test = self.has_uk_phone_fixtures.collect do |fixture|
              fixture = send(self.has_uk_phone_class.table_name, fixture)
              self.has_uk_phone_class.find(fixture.id)
            end
          else
            to_test = self.has_uk_phone_class.find(:all)
          end
          to_test.each do |record|
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
