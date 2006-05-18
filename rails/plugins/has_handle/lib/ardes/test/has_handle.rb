module Ardes# :nodoc:
  module Test# :nodoc:
    module HasHandle
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # example:
        #   class MyTestCase < Test::Unit::TestCase
        #     test_has_handle MyClass, [1, :first_handle], [2, :second_handle]
        def test_has_handle(target_class, *id_handle_pairs)
          include InstanceMethods
          raise(ArgumentError, "At least one |id, handle| pair is required") unless id_handle_pairs.size > 0
          self.class_eval do
            cattr_accessor :has_handle_class, :has_handle_id_handle_pairs
            self.has_handle_class = target_class
            self.has_handle_id_handle_pairs = id_handle_pairs
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
          self.has_handle_id_handle_pairs.each do |id, handle|
            assert(!new_has_handle_object(handle).valid?)
          end
        end

        def test_has_handle_should_be_invalid_if_nil
          assert(!new_has_handle_object(nil).valid?)
        end

        def test_has_handle_should_be_findable_with_handle
          self.has_handle_id_handle_pairs.each do |id, handle|
            obj = self.has_handle_class.find(handle)
            assert_equal id, obj.id
          end
        end

        def test_has_handle_should_be_findable_with_handle_array
          handles = self.has_handle_id_handle_pairs.collect {|pair| pair.last}
          objs = self.has_handle_class.find(handles)
          assert_equal handles.size, objs.size
        end

        def test_has_handle_should_be_findable_with_string_but_numeric_id
          self.has_handle_id_handle_pairs.each do |id, handle|
            obj = self.has_handle_class.find(id.to_s)
            assert_equal id, obj.id
          end
        end

        def test_has_handle_should_ensure_that_find_works_with_handle_and_conditions
          self.has_handle_id_handle_pairs.each do |id, handle|
            obj = self.has_handle_class.find(handle, :conditions => ["id = ?", id])
            assert_equal id, obj.id
            # now use the same handle but a diffrent id
            assert_raise(::ActiveRecord::RecordNotFound) do
              self.has_handle_class.find(handle, :conditions => ["id = ?", id + 1])
            end
          end
        end

        def test_has_handle_should_ensure_that_find_throws_record_not_found_with_bad_handle
          self.has_handle_id_handle_pairs.each do |id, handle|
            # find a record with handle and delete it
            assert self.has_handle_class.find(handle).destroy
            # find it again, should raise error
            assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find(handle) }
          end
        end

        def test_has_handle_should_ensure_find_works_as_it_normally_should
          (id, handle) = self.has_handle_id_handle_pairs.first
          obj = self.has_handle_class.find(id)
          assert_equal id, obj.id
          assert self.has_handle_class.find(id).destroy
          assert_raise(::ActiveRecord::RecordNotFound) { self.has_handle_class.find(id) }
          assert self.has_handle_class.find(:all).size == self.has_handle_id_handle_pairs.size - 1
          assert self.has_handle_class.find(:first) unless self.has_handle_id_handle_pairs.size == 1
          assert(!self.has_handle_class.find(:first, :conditions => ["'handle' = ?", handle]))
        end
        
        def test_has_handle_should_be_existing_with_handle
          (id, handle) = self.has_handle_id_handle_pairs.first
          assert self.has_handle_class.exists?(handle)
        end
        
        def test_has_handle_should_be_existing_with_id
          (id, handle) = self.has_handle_id_handle_pairs.first
          assert self.has_handle_class.exists?(id)
        end
        
        def test_has_handle_should_be_existing_with_string_but_numeric_id
          (id, handle) = self.has_handle_id_handle_pairs.first
          assert self.has_handle_class.exists?(id.to_s)
        end
        
        def test_has_handle_should_not_be_existing_with_non_existent_handle
          (id, handle) = self.has_handle_id_handle_pairs.first
          assert self.has_handle_class.find(id).destroy
          assert(!self.has_handle_class.exists?(handle))
        end
        
        def test_has_handle_should_not_be_existing_with_non_existent_id
          (id, handle) = self.has_handle_id_handle_pairs.first
          assert self.has_handle_class.find(id).destroy
          assert(!self.has_handle_class.exists?(id))
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::HasHandle }
