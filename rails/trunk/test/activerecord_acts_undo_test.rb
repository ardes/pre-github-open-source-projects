require 'load_ar'
require 'test/unit'
require 'ardes/active_record/acts/undo'
require 'acts_as_versioned.rb'

module ActiveRecordActsUndoTest
  class FineProduct < ActiveRecord::Base
    acts_as_undoable :products
    has_many :fine_product_parts, :dependent => true
  end
    
  class FineProductPart < ActiveRecord::Base
    acts_as_undoable :products
    belongs_to :fine_product
  end

  class ActsAsUndoTest < Test::Unit::TestCase
    def setup
      @manager = Ardes::ActiveRecord::Undo::Versioned::Manager.for :products
    end
    
    def test_manager_linked
      assert_same @manager, FineProduct.undo_manager
      assert_same @manager, FineProductPart.undo_manager
      assert_same ProductUndoItem, @manager.stack
    end
  
    def test_create_undo_redo
      fine = nil
      @manager.execute do
        fine = FineProduct.create()
      end
    
      @manager.undo # will undo the creation of 'fine'
      assert_equal nil, FineProduct.find(:first, :conditions => ["id = ?",fine.id])
    
      @manager.redo # redo the creation of 'fine'
      assert_equal fine, FineProduct.find(:first, :conditions => ["id = ?",fine.id])
    end
  
    def test_destroy_undo_redo
      fine = FineProduct.create()
    
      @manager.execute do
        fine.dup.destroy
      end
    
      @manager.undo # will undo the deletion of 'fine'
      assert_equal fine, FineProduct.find(:first, :conditions => ["id = ?",fine.id])
    
      @manager.redo # redo the deletion of 'fine'
      assert_equal nil, FineProduct.find(:first, :conditions => ["id = ?",fine.id])
    end  
  
    def test_change_undo_redo
      fine = FineProduct.create(:name => 'fine')
    
      @manager.execute do
        fine.name = 'dandy'
        fine.save
      end
    
      @manager.undo # will undo the change of 'fine' to 'dandy'
      assert_equal      fine, FineProduct.find_by_name('fine')
      assert_not_equal  fine, FineProduct.find_by_name('dandy')
    
      @manager.redo # redo those changes again
      assert_not_equal  fine, FineProduct.find_by_name('fine')
      assert_equal      fine, FineProduct.find_by_name('dandy')
    end
  
    def test_complex_undo_redo
      fine_count = FineProduct.count
      part_count = FineProductPart.count

      chandelier   = nil
      gold_leaf    = nil
      glass_bead_1 = nil
      glass_bead_2 = nil

      # start with a new chandelier
      chandelier_created_with_gold_leaf = @manager.execute do
        chandelier = FineProduct.create(:name => 'chandelier')
        chandelier.fine_product_parts << (gold_leaf = FineProductPart.new(:name => 'gold leaf'))
        chandelier.save
      end
      assert_equal fine_count + 1, FineProduct.count
      assert_equal part_count + 1, FineProductPart.count

      # add some glass beads
      glass_beads_added = @manager.execute do
        chandelier.fine_product_parts << (glass_bead_1 = FineProductPart.new(:name => 'glass bead'))
        chandelier.fine_product_parts << (glass_bead_2 = FineProductPart.new(:name => 'glass bead'))
        chandelier.save
      end
      assert_equal fine_count + 1, FineProduct.count
      assert_equal part_count + 3, FineProductPart.count
      
      # now junk the chandelier (and the dependent parts)
      chandelier_destroyed = @manager.execute do
        FineProduct.find(chandelier.id).destroy
      end
      assert_equal fine_count, FineProduct.count
      assert_equal part_count, FineProductPart.count
      
      # NOW, lets undo some of that
      
      @manager.undo glass_beads_added # will undo the destroy, and the glass_beads
      assert_equal fine_count + 1, FineProduct.count
      assert_equal part_count + 1, FineProductPart.count
      
      @manager.redo glass_beads_added # add the beads again
      assert_equal fine_count + 1, FineProduct.count
      assert_equal part_count + 3, FineProductPart.count
      
      # getting rid of chandelier will undo all ops to that point, which means no hanging foriegn keys
      @manager.undo chandelier_created_with_gold_leaf  
      assert_equal fine_count, FineProduct.count
      assert_equal part_count, FineProductPart.count
    end
  end
end
