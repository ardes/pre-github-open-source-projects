require 'load_ar'
require 'test/unit'
require 'ardes/active_record/undo/versioned'
require 'acts_as_versioned.rb'

module ActiveRecordUndoVersionedTest
  class UndoVersionedItem < ActiveRecord::Base
    acts_as_versioned_undo_stack
  end
  
  require 'abstract/undo/item'
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
  
  class VersionedManagerTest < Test::Unit::TestCase
    
    class Product < ActiveRecord::Base
      acts_as_versioned
    end
    
    def setup
      @manager = Ardes::ActiveRecord::Undo::Versioned::Manager.for :products
    end
    
    def test_manager_linked
      assert_kind_of Ardes::ActiveRecord::Undo::Versioned::Manager, @manager
      assert_equal ProductUndoItem, @manager.stack
    end
    
    def test_create_undo_redo
      product_count = Product.count
      @manager.execute do
        Product.create(:name => 'product')
        Product.create(:name => 'product')
        Product.create(:name => 'product')
      end
      assert_equal product_count + 3, Product.count
      @manager.undo
      assert_equal product_count + 2, Product.count
      @manager.redo
      assert_equal product_count + 3, Product.count
    end
  end
end