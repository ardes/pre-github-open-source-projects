module Ardes
  module Test
    module ActsAsUndoable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Assumes that there is a valid data in the table
        def test_acts_as_undoable(target_class, fixture, attrs)
          include InstanceMethods
          self.class_eval do
            cattr_accessor :acts_as_undoable_class, :acts_as_undoable_fixture, :acts_as_undoable_attrs
            self.acts_as_undoable_class = target_class
            self.acts_as_undoable_fixture = fixture
            self.acts_as_undoable_attrs = attrs
          end
        end
      end

      module InstanceMethods
        def test_should_undo_destroy
          obj = send(self.acts_as_undoable_class.table_name, self.acts_as_undoable_fixture)
          
          obj.undoable { obj.destroy }
          assert_raise(::ActiveRecord::RecordNotFound) { obj.class.find(obj.id) }
          obj.undo_manager.undo
          assert_equal obj, obj.class.find(obj.id)
        end
        
        def test_should_undo_update
          obj = send(self.acts_as_undoable_class.table_name, self.acts_as_undoable_fixture)
          prev = obj.clone
          
          attrs = {}
          self.acts_as_undoable_attrs.each {|k, v| attrs[k] = v.is_a?(Proc) ? v.call : v }
          
          obj.undoable { obj.update_attributes(attrs) }
          attrs.each do |k,v|
            assert_equal v, obj.send(k)
          end
          
          obj.undo_manager.undo
          obj.reload
          
          prev.attributes.keys.each do |k| 
            assert_equal prev.send(k), obj.send(k)
          end
        end
        
        def test_should_undo_create
          obj_count = self.acts_as_undoable_class.count
          
          attrs = {}
          self.acts_as_undoable_attrs.each {|k, v| attrs[k] = v.is_a?(Proc) ? v.call : v }
          
          self.acts_as_undoable_class.undoable { obj = self.acts_as_undoable_class.create(attrs)}
          assert_equal obj_count + 1, self.acts_as_undoable_class.count
          
          self.acts_as_undoable_class.undo_manager.undo
          
          assert_equal obj_count, self.acts_as_undoable_class.count
        end
        
        def test_should_work_with_undo_all
          old_undo_all_val = self.acts_as_undoable_class.undo_all
          
          # test with undo all TRUE
          self.acts_as_undoable_class.undo_all = true
          obj = send(self.acts_as_undoable_class.table_name, self.acts_as_undoable_fixture)
          obj.destroy
          
          undoable_desc = "destroy " + (obj.respond_to?(:obj_desc) ? obj.obj_desc : "#{obj.class.name.underscore.sub('_',' ')}: #{obj.id}")
          assert_equal undoable_desc, obj.undo_manager.undoables(:first).description
        
          obj.undo_manager.undo
          assert_equal obj, obj.class.find(obj.id)
          
          # test without undo
          undoables_before = obj.undo_manager.undoables
          obj.without_undo { obj.destroy }
          assert_equal undoables_before, obj.undo_manager.undoables
          
          self.acts_as_undoable_class.undo_all = old_undo_all_val
        end
      end
    end
  end
end

Test::Unit::TestCase.class_eval { include Ardes::Test::ActsAsUndoable }
