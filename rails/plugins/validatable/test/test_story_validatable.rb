# story test extension for validatable mixin
#
# assumes that there are attribute accessors for the target class
#
module TestStoryValidatable
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def test_story_validatable(target_class, valid_attrs = [], invalid_attrs = [])
      include InstanceMethods
      cattr_accessor :test_story_validatable_class, :test_story_validatable_valid_attrs, :test_story_validatable_invalid_attrs
      self.test_story_validatable_class         = target_class
      self.test_story_validatable_valid_attrs   = valid_attrs
      self.test_story_validatable_invalid_attrs = invalid_attrs
    end
  end
  
  module InstanceMethods
    def test_story_validatable_should_validate_object_with_valid_attributes
      obj = self.test_story_validatable_class.new
      self.test_story_validatable_valid_attrs.each {|a,v| obj.send(a.to_s + "=",v)}
      assert obj.valid?
    end

    def test_story_validatable_should_not_validate_object_with_invalid_attributes
      obj = self.test_story_validatable_class.new
      self.test_story_validatable_invalid_attrs.each {|a,v| obj.send(a.to_s + "=",v)}
      assert(!obj.valid?)
    end
  end
end

Test::Unit::TestCase.class_eval { include TestStoryValidatable }