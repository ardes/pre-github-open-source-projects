module Ardes
  module Test
    module ActsAsUndoable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_acts_as_undoable(target_class, attrs)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :acts_as_undoable_class, :acts_as_undoable_attrs
            self.acts_as_undoable_class = target_class
            self.acts_as_undoable_attrs = attrs
          end
        end
      end

      module InstanceMethods
        def test_should_undo_destroy
          obj = self.acts_as_undoable_class.find_first
          
          obj.undoable { obj.destroy }
          assert_raise(::ActiveRecord::RecordNotFound) { obj.class.find(obj.id) }
          obj.undo_manager.undo
          assert_equal obj, obj.class.find(obj.id)
        end
        
        def test_should_undo_update
          obj = self.acts_as_undoable_class.find_first
          prev_attrs = obj.attributes
          
          obj.undoable { obj.update_attributes(self.acts_as_undoable_attrs) }
          self.acts_as_undoable_attrs.each do |k,v|
            assert_equal v, obj.send(k)
          end
          
          obj.undo_manager.undo
          obj.reload
          
          prev_attrs.each do |k,v| 
            assert_equal v, obj.send(k)
          end
        end
        
        def test_should_undo_create
          obj_count = self.acts_as_undoable_class.count
          
          self.acts_as_undoable_class.undoable { self.acts_as_undoable_class.create(self.acts_as_undoable_attrs)}
          assert_equal obj_count + 1, self.acts_as_undoable_class.count
          
          self.acts_as_undoable_class.undo_manager.undo
          
          assert_equal obj_count, self.acts_as_undoable_class.count
        end
        
        def test_should_work_with_undo_all
          old_undo_all_val = self.acts_as_undoable_class.undo_all
          
          # test with undo all TRUE
          self.acts_as_undoable_class.undo_all = true
          obj = self.acts_as_undoable_class.find_first
          obj.destroy
          
          undoable_desc = "destroy " + (obj.respond_to?(:obj_desc) ? obj.obj_desc : "#{obj.class.name.underscore.sub('_',' ')}: #{obj.id}")
          assert_equal undoable_desc, obj.undo_manager.undoables(:first).description
    
          obj.undo_manager.undo
          assert_equal obj, obj.class.find(obj.id)
          
          # test with undo all FALSE
          self.acts_as_undoable_class.undo_all = false
          undoables_before = obj.undo_manager.undoables
          obj.destroy
          assert_equal undoables_before, obj.undo_manager.undoables
          
          self.acts_as_undoable_class.undo_all = old_undo_all_val
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::ActsAsUndoable }
