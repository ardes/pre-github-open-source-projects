require 'load_ar'
require 'test/unit'
require 'ardes/undo/versioned'
require 'acts_as_versioned.rb'

module ArdesTests
  module UndoVersioned
    class ::UndoVersionedItem < ActiveRecord::Base
      include Ardes::Undo::Versioned::ActiveRecordStack
    end
  
    require 'abstract/undo/item'
    class ItemTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Item
  
      def setup_objects
        @item = UndoVersionedItem.new
        @undone_result = true
        @redone_result = true
      end
    end

    require 'abstract/undo/stack'
    class StackTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Stack

      def setup_objects
        @stack = UndoVersionedItem
        UndoVersionedItem.delete_all
        @new_item_proc = Proc.new { UndoVersionedItem.new }
      end
    end

    require 'abstract/undo/manager'
    class ManagerTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::Manager
  
      def setup_objects
        @manager = Ardes::Undo::Versioned::Manager.new UndoVersionedItem
        UndoVersionedItem.delete_all
        @new_item_proc = Proc.new { UndoVersionedItem.new }
      end
    end
    
    class ::VFineProduct < ActiveRecord::Base
      has_many :v_fine_product_parts, :dependent => true
      cattr_accessor :undo_manager
      self.undo_manager = Ardes::Undo::Versioned::Manager.for :v_products
      self.undo_manager.manage(self)      
      acts_as_versioned
    end

    class ::VFineProductPart < ActiveRecord::Base
      belongs_to :v_fine_product
      cattr_accessor :undo_manager
      self.undo_manager = Ardes::Undo::Versioned::Manager.for :v_products
      self.undo_manager.manage(self)      
      acts_as_versioned
    end
    
    require 'abstract/undo/versioned'
    class VersionedManagerTest < Test::Unit::TestCase
      include ArdesTests::Abstract::Undo::VersionedManager
      
      def setup_objects
        @fine_class = VFineProduct
        @part_class = VFineProductPart
        @manager = Ardes::Undo::Versioned::Manager.for :v_products
      end
    end
  end
end