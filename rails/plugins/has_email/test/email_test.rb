require File.dirname(__FILE__) + '/test_helper'
require 'ardes/email'

class EmailTest < Test::Unit::TestCase
  
  def test_should_remove_cruft
    assert_equal 'ian@ardes.com', Ardes::Email.new('   ian@ardes.com     ').to_s
  end
  
  def test_should_be_identicial_when_sane
    assert_equal 'ian@ardes.com', Ardes::Email.new('ian@ardes.com').to_s
  end
  
  def test_should_have_equality_for_objects_with_same_email
    assert_equal Ardes::Email.new("ian@ARDES.com"), Ardes::Email.new("IAN@ARDES.com")
  end
  
  def test_should_have_equality_for_objects_with_same_number_including_cruft
    assert_equal Ardes::Email.new("ian@ardes.com"), Ardes::Email.new("  ian@ardes.com   ")
  end
  
  def test_canonical_representation
    assert_equal 'ian@ardes.com', Ardes::Email.new("  IAN@ARDES.com   ").canonical
  end
end
