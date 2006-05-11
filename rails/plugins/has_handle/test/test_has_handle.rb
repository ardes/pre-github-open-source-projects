module TestHasHandle

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def test_has_handle(target_class)
      include InstanceMethods
      self.class_eval do
        cattr_accessor :has_handle_class
        self.has_handle_class = target.to_s.classify.constantize
        alias_method_chain :setup, :has_handle
      end
    end
  end

  module InstanceMethods
    def setup_with_has_handle
      @has_handle_obj = self.has_handle_class.new
      setup_without_has_handle
    end

    # uses the handle_column attribute
    def set_handle(obj, handle)
      obj.send(obj.handle_column.to_s + "=", handle)
    end

    def test_should_be_valid_with_handle_containing_only_lowercase_alphanumeric_and_underscores
      set_handle(@has_handle_obj, 'h4n_dle')
      assert @has_handle_obj.valid?
    end

    def test_should_be_invalid_with_handle_containing_uppercase
      set_handle(@has_handle_obj, 'H4n_dle')
      deny @has_handle_obj.valid?
    end

    def test_should_be_invalid_with_handle_containing_space
      set_handle(@has_handle_obj, 'h4n dle')
      deny @has_handle_obj.valid?
    end

    def test_should_be_invalid_with_handle_larger_than_64
      set_handle(@has_handle_obj, '0123456789_and_01234567890_and_1234567890_and_1234567890_and_1234567890_and_01234567890')
      deny @has_handle_obj.valid?
    end

    def test_should_be_invalid_with_handle_zero_length_string
      set_handle(@has_handle_obj, '')
      deny @has_handle_obj.valid?
    end

    def test_should_be_invalid_if_duplicate
      set_handle(@has_handle_obj, 'first')
      deny @has_handle_obj.valid?
    end

    def test_should_be_invalid_if_nil
      set_handle(@has_handle_obj, nil)
      deny @has_handle_obj.valid?
    end

    def test_should_be_findable_with_handle
      first = self.has_handle_class.find('first')
      assert_equal 1, first.id
    end

    def test_should_be_findable_with_handle_array
      objs = self.has_handle_class.find(['first', 'second'])
      assert_equal 2, objs.size
    end

    def test_should_be_findable_with_string_but_numeric_id
      first = self.has_handle_class.find("1")
      assert_equal 1, first.id
    end

    def test_should_ensure_that_find_works_with_handle_and_conditions
      first = self.has_handle_class.find('first', :conditions => ["id = ?", 1])
      assert_equal 1, first.id
      assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find('first', :conditions => ["id = ?", 2]) }
    end

    def test_should_ensure_that_find_throws_record_not_found_with_bad_handle
      assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find('not_there') }
    end

    def test_should_ensure_find_works_as_it_normally_should
      first = self.has_handle_class.find(1)
      assert_equal 1, first.id
      assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find(1, :conditions => ["'handle' = ?", 'not_there']) }
      assert self.has_handle_class.find(:all).size >= 1
      assert self.has_handle_class.find(:first)
      deny self.has_handle_class.find(:first, :conditions => ["'handle' = ?", 'not_there'])
    end
  end
end

Test::Unit::TestCase.class_eval { include TestHasHandle }
