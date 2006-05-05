require File.dirname(__FILE__) + '/../test_helper'
require 'ardes/validatable'

class ObjectWithValidation
  include Ardes::Validatable
  attr_reader :name
  validates_format_of :name, :with => /ian/
  
  def initialize(name = nil)
    @name = name
  end
end

class Ardes::TestCase::Validatable < Test::Rails::TestCase

  def test_should_respond_to_valid_eh
    obj = ObjectWithValidation.new
    assert obj.respond_to? 'valid?'
  end
  
  def test_should_validate_only_valid_object
    obj = ObjectWithValidation.new('ooooo')
    deny obj.valid?
    obj = ObjectWithValidation.new('ian')
    assert obj.valid?
  end
end