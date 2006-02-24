require 'load_ar'
require 'test/unit'
require 'ardes/active_record/acts/undo'
require 'acts_as_versioned.rb'

module ArdesTests
  module Abstract
    module Undo
      module VersionedManager
        def setup
          setup_objects
        end
  
        def test_manager_linked
          assert_same @manager, @fine_class.undo_manager
          assert_same @manager, @part_class.undo_manager
        end

        def test_create_undo_redo
          fine = nil
          @manager.execute do
            fine = @fine_class.create()
          end
  
          @manager.undo # will undo the creation of 'fine'
          assert_equal nil, @fine_class.find(:first, :conditions => ["id = ?",fine.id])
  
          @manager.redo # redo the creation of 'fine'
          assert_equal fine, @fine_class.find(:first, :conditions => ["id = ?",fine.id])
        end

        def test_destroy_undo_redo
          fine = @fine_class.create()
  
          @manager.execute do
            fine.dup.destroy
          end
  
          @manager.undo # will undo the deletion of 'fine'
          assert_equal fine, @fine_class.find(:first, :conditions => ["id = ?",fine.id])
  
          @manager.redo # redo the deletion of 'fine'
          assert_equal nil, @fine_class.find(:first, :conditions => ["id = ?",fine.id])
        end  

        def test_change_undo_redo
          fine = @fine_class.create(:name => 'fine')
  
          @manager.execute do
            fine.name = 'dandy'
            fine.save
          end
  
          @manager.undo # will undo the change of 'fine' to 'dandy'
          assert_equal      fine, @fine_class.find_by_name('fine')
          assert_not_equal  fine, @fine_class.find_by_name('dandy')
  
          @manager.redo # redo those changes again
          assert_not_equal  fine, @fine_class.find_by_name('fine')
          assert_equal      fine, @fine_class.find_by_name('dandy')
        end

        def test_complex_undo_redo
          fine_count = @fine_class.count
          part_count = @part_class.count

          c = nil
        
          # start with a new chandelier
          chandelier_created_with_gold_leaf = @manager.execute do
            c = @fine_class.create(:name => 'chandelier')
            parts = c.send(@part_class.name.tableize)
            parts << @part_class.new(:name => 'gold leaf')
            c.save
          end
          assert_equal fine_count + 1, @fine_class.count
          assert_equal part_count + 1, @part_class.count

          # add some glass beads
          glass_beads_added = @manager.execute do
            parts = c.send(@part_class.name.tableize)
            parts << @part_class.new(:name => 'glass bead')
            parts << @part_class.new(:name => 'glass bead')
            c.save
          end
          assert_equal fine_count + 1, @fine_class.count
          assert_equal part_count + 3, @part_class.count
    
          # now junk the chandelier (and the dependent parts)
          chandelier_destroyed = @manager.execute do
            @fine_class.find(c.id).destroy
          end
          assert_equal fine_count, @fine_class.count
          assert_equal part_count, @part_class.count
    
          # NOW, lets undo some of that
    
          @manager.undo glass_beads_added # will undo the destroy, and the glass_beads
          
          assert_equal fine_count + 1, @fine_class.count
          assert_equal part_count + 1, @part_class.count
    
          @manager.redo glass_beads_added # add the beads again
          assert_equal fine_count + 1, @fine_class.count
          assert_equal part_count + 3, @part_class.count
    
          # getting rid of chandelier will undo all ops to that point, which means no hanging foriegn keys
          @manager.undo chandelier_created_with_gold_leaf  
          assert_equal fine_count, @fine_class.count
          assert_equal part_count, @part_class.count
        end
      
        def clear_schema
          ActiveRecord::Base.connection.initialize_schema_information
          ActiveRecord::Base.connection.update "UPDATE schema_info SET version = 0" rescue nil
          ActiveRecord::Base.connection.drop_table "thing_undo_items" rescue nil
        end

        def test_migration_methods
          clear_schema
          
          m = @manager.class.for :things
          assert_raises(ActiveRecord::StatementInvalid) { m.stack.count }
          # take 'er up
          m.create_tables
          m.stack.create
          assert_equal 1, m.stack.count
          # now lets take 'er back down
          m.drop_tables
          assert_raises(ActiveRecord::StatementInvalid) { m.stack.count }
          
          clear_schema
        end  
      end
    end
  end
end