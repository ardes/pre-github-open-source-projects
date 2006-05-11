# unit test extension for validatable mixin
#
# assumes that there are attribute accessors for the target class
#
module Test
  module Abstract
    module Validatable
      def self.included(base)
        base.extend ClassMethods
      end
  
      module ClassMethods
        def test_validatable(target_class, valid_attrs, invalid_attrs)
          include InstanceMethods
          cattr_accessor :validatable_class, :validatable_valid_attrs, :validatable_invalid_attrs
          self.validatable_class         = target_class
          self.validatable_valid_attrs   = valid_attrs
          self.validatable_invalid_attrs = invalid_attrs
        end
      end
  
      module InstanceMethods
        def test_validatable_valid_eh
          obj = self.validatable_class.new
          assert obj.respond_to?('valid?')
        end
    
        def test_validatable_method_missing_should_respond_to_before_type_cast
          obj = self.validatable_class.new
          self.validatable_valid_attrs.each do |a,v|
            obj.send(a.to_s + "=",v)
            assert_equal obj.send(a), obj.send(a.to_s + "_before_type_cast")
          end
        end
    
        def test_validatable_class_human_attribute_name
          assert_equal "My attr", self.validatable_class.human_attribute_name("my_attr")
        end
    
        def test_validatable_respond_to_eh_methods_required_for_validation
          obj = self.validatable_class.new
          [:save, :update_attribute, :save!].each do |method|
            assert obj.respond_to?(method)
          end
        end
    
        def test_validatable_index
          obj = self.validatable_class.new
      
          self.validatable_valid_attrs.each do |a,v|
            obj.send(a.to_s + "=", v)
            assert_equal v, obj[a]
          end
        end
    
        def test_validatable_should_validate_object_with_valid_attributes
          obj = self.validatable_class.new
          self.validatable_valid_attrs.each {|a,v| obj.send(a.to_s + "=",v)}
          assert obj.valid?
        end

        def test_validatable_should_not_validate_object_with_invalid_attributes
          obj = self.validatable_class.new
          self.validatable_invalid_attrs.each {|a,v| obj.send(a.to_s + "=",v)}
          assert(!obj.valid?)
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Test::Abstract::Validatable }