require 'load_ar'
require 'test/unit'
require 'ardes/active_record/undo'

module ArdesTests
  module ActiveRecordUndo
    class UndoItem < ActiveRecord::Base
      acts_as_undo_stack
    protected
      def on_undo; "undone"; end
      def on_redo; "redone"; end
    end
  
    require 'abstract/undo/item'
    class ItemTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Item
  
      def setup_objects
        @item = UndoItem.new
        @undone_result = "undone"
        @redone_result = "redone"
      end
  
    end

    require 'abstract/undo/stack'
    class StackTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Stack

      def setup_objects
        @stack = UndoItem
        UndoItem.delete_all
        @new_item_proc = Proc.new { UndoItem.new }
      end
    end

    require 'abstract/undo/manager'
    class ManagerTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Manager
  
      def setup_objects
        @manager = Ardes::Undo::Manager.new UndoItem
        UndoItem.delete_all
        @new_item_proc = Proc.new { UndoItem.new }
      end
    end
  end
end