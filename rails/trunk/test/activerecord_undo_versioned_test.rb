require 'load_ar'
require 'test/unit'
require 'ardes/active_record/undo/versioned'

module ActiveRecordUndoVersionedTest
  class UndoVersionedItem < ActiveRecord::Base
    acts_as_versioned_undo_stack
  end
  
  require 'abstract/undo/item'
  # TODO thing
  class ItemTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Item
  
    def setup_objects
      @item = UndoVersionedItem.new
      @undone_result = true
      @redone_result = true
    end
  end

  require 'abstract/undo/stack'
  class StackTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Stack

    def setup_objects
      @stack = UndoVersionedItem
      UndoVersionedItem.delete_all
      @new_item_proc = Proc.new { UndoVersionedItem.new }
    end
  end

  require 'abstract/undo/manager'
  class ManagerTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Manager
  
    def setup_objects
      @manager = Ardes::ActiveRecord::Undo::Versioned::Manager.new UndoVersionedItem
      UndoVersionedItem.delete_all
      @new_item_proc = Proc.new { UndoVersionedItem.new }
    end
  end
end