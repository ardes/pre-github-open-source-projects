require 'load_ar'
require 'test/unit'
require 'ardes/undo/versioned'
require 'acts_as_versioned.rb'

module ArdesTests
  module ActiveRecordUndoVersioned
    class UndoVersionedItem < ActiveRecord::Base
      include Ardes::Undo::Versioned::ActiveRecord
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
    
    class MigrationTest < Test::Unit::TestCase
      
      def setup
        ActiveRecord::Base.connection.initialize_schema_information
        ActiveRecord::Base.connection.update "UPDATE schema_info SET version = 0"
        ActiveRecord::Base.connection.drop_table "thing_undo_items" rescue nil
      end
      
      alias_method :teardown, :setup

      def test_versioned_migration
        m = Ardes::Undo::Versioned::Manager.for :things
        assert_raises(ActiveRecord::StatementInvalid) { m.stack.count }
        # take 'er up
        ActiveRecord::Migrator.up(File.dirname(__FILE__) + '/fixtures/migrations/')
        m.stack.create
        assert_equal 1, m.stack.count
        # now lets take 'er back down
        ActiveRecord::Migrator.down(File.dirname(__FILE__) + '/fixtures/migrations/')
        assert_raises(ActiveRecord::StatementInvalid) { m.stack.count }
      end
    end
  end
end