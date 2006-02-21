require 'test/unit'
require 'ardes/undo'

module UndoTest
  class Item
    include Ardes::Undo::AbstractItem
  
    attr_accessor :undone
    def undone?; !!undone; end

    def initialize(name=""); @name = name; end

  protected
    def on_undo; "#{@name} undone"; end
    def on_redo; "#{@name} redone"; end
  end

  class Stack
    include Ardes::Undo::AbstractStack

    def initialize; @storage = Hash.new; @idx = 0; end
    def delete_undone_items; @storage.delete_if{|k,i| i.undone?}; end
    def push_item(item); @storage[@idx += 1] = item; @idx; end
    
    def item_at(id)
      item = @storage[id]
      yield(item) if block_given?
    end
    
    def each_id_item(reverse = false)
      items = @storage.sort
      items.reverse! if reverse
      items.each { |id,item| yield(id, item)}
    end
  end

  require 'abstract/undo/item'
  class ItemTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Item
  
    def setup_objects
      @item = Item.new "test"
      @undone_result = "test undone"
      @redone_result = "test redone"
    end
  
  end

  require 'abstract/undo/stack'
  class StackTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Stack

    def setup_objects
      @stack = Stack.new
      @new_item_proc = Proc.new { Item.new }
    end
  end

  require 'abstract/undo/manager'
  class ManagerTest < Test::Unit::TestCase
    include Test::Abstract::Undo::Manager
  
    def setup_objects
      @manager = Ardes::Undo::Manager.new Stack.new
      @new_item_proc = Proc.new { Item.new }
    end
  end
end