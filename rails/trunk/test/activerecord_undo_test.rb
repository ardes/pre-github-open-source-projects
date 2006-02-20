require 'active_record'
require 'test/unit'
require 'ardes/active_record/undo'

module ActiveRecordUndoTest
  class Stack < ActiveRecord::Base
    acts_as_undo_stack
  end
  
  require 'abstract/undo/item'
  class ItemTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Item
  
    def setup_objects
      @item = Stack.new
      @undone_result = "undone"
      @redone_result = "redone"
    end
  
  end

  require 'abstract/undo/stack'
  class StackTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Stack

    def setup_objects
      @stack = Stack
      @new_item_proc = Proc.new { Stack.new }
    end
  end

  require 'abstract/undo/manager'
  class ManagerTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Manager
  
    def setup_objects
      @manager = Ardes::Undo::Manager.new Stack
      @new_item_proc = Proc.new { Stack.new }
    end
  end
end