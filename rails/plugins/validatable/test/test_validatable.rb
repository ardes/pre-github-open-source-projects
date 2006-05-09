# unit test extension for validatable mixin
#
# assumes that there are attribute accessors for the target class
#
module TestValidatable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def test_validatable(target_class, attrs = [])
      include InstanceMethods
      cattr_accessor :test_validatable_class, :test_validatable_attrs
      self.test_validatable_class = target_class
      self.test_validatable_attrs = attrs
    end
  end
  
  module InstanceMethods
    def test_validatable_valid_eh
      obj = self.test_validatable_class.new
      assert obj.respond_to?('valid?')
    end
    
    def test_validatable_method_missing_should_respond_to_before_type_cast
      obj = self.test_validatable_class.new
      self.test_validatable_attrs.each do |a,v|
        obj.send(a.to_s + "=",v)
        assert_equal obj.send(a), obj.send(a.to_s + "_before_type_cast")
      end
    end
    
    def test_validatable_class_human_attribute_name
      assert_equal "My attr", self.test_validatable_class.human_attribute_name("my_attr")
    end
    
    def test_validatable_respond_to_eh_methods_required_for_validation
      obj = self.test_validatable_class.new
      [:save, :update_attribute, :save!].each do |method|
        assert obj.respond_to?(method)
      end
    end
    
    def test_validatable_index
      obj = self.test_validatable_class.new
      
      self.test_validatable_attrs.each do |a,v|
        obj.send(a.to_s + "=", v)
        assert_equal v, obj[a]
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include TestValidatable }