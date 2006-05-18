module Ardes# :nodoc:
  module Test# :nodoc:
    module HasHandle
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there are two records with id,handle => {1, 'first'}, {2, 'second'}
        def test_has_handle(target_class)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :has_handle_class
            self.has_handle_class = target_class
          end
        end
      end

      module InstanceMethods
    
        def new_has_handle_object(handle = nil)
          obj = self.has_handle_class.new
          obj.send(obj.handle_column.to_s + "=", handle) if handle
          obj
        end

        def test_has_handle_should_be_valid_with_handle_containing_only_lowercase_alphanumeric_and_underscores
          assert new_has_handle_object('h4n_dle').valid?
        end

        def test_has_handle_should_be_invalid_with_handle_containing_uppercase
          assert(!new_has_handle_object('H4n_dle').valid?)
        end

        def test_has_handle_should_be_invalid_with_handle_containing_space
          assert(!new_has_handle_object('h4n dle').valid?)
        end

        def test_has_handle_should_be_invalid_with_handle_larger_than_64
          assert(!new_has_handle_object('0123456789_and_01234567890_and_1234567890_and_1234567890_and_1234567890_and_01234567890').valid?)
        end

        def test_has_handle_should_be_invalid_with_handle_zero_length_string
          assert(!new_has_handle_object('').valid?)
        end

        def test_has_handle_should_be_invalid_if_duplicate
          assert(!new_has_handle_object('first').valid?)
        end

        def test_has_handle_should_be_invalid_if_nil
          assert(!new_has_handle_object(nil).valid?)
        end

        def test_has_handle_should_be_findable_with_handle
          first = self.has_handle_class.find('first')
          assert_equal 1, first.id
        end

        def test_has_handle_should_be_findable_with_handle_array
          objs = self.has_handle_class.find(['first', 'second'])
          assert_equal 2, objs.size
        end

        def test_has_handle_should_be_findable_with_string_but_numeric_id
          first = self.has_handle_class.find("1")
          assert_equal 1, first.id
        end

        def test_has_handle_should_ensure_that_find_works_with_handle_and_conditions
          first = self.has_handle_class.find('first', :conditions => ["id = ?", 1])
          assert_equal 1, first.id
          assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find('first', :conditions => ["id = ?", 2]) }
        end

        def test_has_handle_should_ensure_that_find_throws_record_not_found_with_bad_handle
          assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find('not_there') }
        end

        def test_has_handle_should_ensure_find_works_as_it_normally_should
          first = self.has_handle_class.find(1)
          assert_equal 1, first.id
          assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find(1, :conditions => ["'handle' = ?", 'not_there']) }
          assert self.has_handle_class.find(:all).size >= 1
          assert self.has_handle_class.find(:first)
          assert(!self.has_handle_class.find(:first, :conditions => ["'handle' = ?", 'not_there']))
        end
        
        def test_has_handle_should_be_existing_with_handle
          assert self.has_handle_class.exists?('first')
        end
        
        def test_has_handle_should_be_existing_with_id
          assert self.has_handle_class.exists?(1)
        end
        
        def test_has_handle_should_be_existing_with_string_but_numeric_id
          assert self.has_handle_class.exists?("1")
        end
        
        def test_has_handle_should_not_be_existing_with_non_existent_handle
          assert(!self.has_handle_class.exists?('not_there'))
        end
        
        def test_has_handle_should_not_be_existing_with_non_existent_id
          assert(!self.has_handle_class.exists?(666))
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::HasHandle }
