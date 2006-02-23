require 'load_ar'
require 'test/unit'
require 'ardes/undo/versioned'
require 'acts_as_versioned.rb'

module ArdesTests
  # TODO add grouping specific tests
  # 
  module UndoVersionedGrouping
    class ::UndoVersionedGroupingItem < ActiveRecord::Base
      include Ardes::Undo::Versioned::Grouping::ActiveRecordStack
    end
  
    require 'abstract/undo/item'
    class ItemTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Item
  
      def setup_objects
        @item = UndoVersionedGroupingItem.new
        @undone_result = []
        @redone_result = []
      end
    end

    require 'abstract/undo/stack'
    class StackTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Stack

      def setup_objects
        @stack = UndoVersionedGroupingItem
        UndoVersionedGroupingItem.delete_all
        UndoVersionedGroupingItem.atoms.delete_all
        @new_item_proc = Proc.new { UndoVersionedGroupingItem.new }
      end
    end

    require 'abstract/undo/manager'
    class ManagerTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Manager
  
      def setup_objects
        @manager = Ardes::Undo::Versioned::Grouping::Manager.new UndoVersionedGroupingItem
        UndoVersionedGroupingItem.delete_all
        UndoVersionedGroupingItem.atoms.delete_all
        @new_item_proc = Proc.new { UndoVersionedGroupingItem.new }
      end
    end
    
    class ::GFineProduct < ActiveRecord::Base
      has_many :g_fine_product_parts, :dependent => true
      cattr_accessor :undo_manager
      self.undo_manager = Ardes::Undo::Versioned::Grouping::Manager.for :g_products
      self.undo_manager.manage(self)      
      acts_as_versioned
    end

    class ::GFineProductPart < ActiveRecord::Base
      belongs_to :g_fine_product
      cattr_accessor :undo_manager
      self.undo_manager = Ardes::Undo::Versioned::Grouping::Manager.for :g_products
      self.undo_manager.manage(self)      
      acts_as_versioned
    end
    
    require 'abstract/undo/versioned'
    class VersionedManagerTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::VersionedManager
      
      def setup_objects
        @fine_class = GFineProduct
        @part_class = GFineProductPart
        @manager = Ardes::Undo::Versioned::Grouping::Manager.for :g_products
      end
    end
  end
end