module Test
  module Abstract
    module Undo
      #
      # the setup_objects method should instantiate the following
      #   @manager        # an undo manager
      #   @new_item_proc  # proc that returns a new item
      # 
      module Manager
        def setup
          setup_objects
          @stack = @manager.stack
          @ids = (0..2).collect {@stack.push_item(@new_item_proc.call)}
        end
        
        def test_manager
          @manager.undo :all
          
          result = []; @stack.each_id_item {|id,item| result << item.undone?}
          assert_equal [true, true, true], result
          assert_equal [], @manager.undo(:first)
          
          assert_equal [@ids[0]], @manager.redo
          result = []; @stack.each_id_item {|id,item| result << item.undone?}
          assert_equal [false, true, true], result
          
          @manager.redo :all
          result = []; @stack.each_id_item {|id,item| result << item.undone?}
          assert_equal [false, false, false], result
          
          assert_equal [@ids[2], @ids[1]], @manager.undo(@ids[1])
          
          result = []; @stack.each_id_item {|id,item| result << item.undone?}
          assert_equal [false, true, true], result
          
          @manager.redo
          
          assert_equal [@ids[1], @ids[0]], @manager.undoables
          assert_equal [@ids[2]], @manager.redoables
          
          @manager.undo

          assert_equal [@ids[0]], @manager.undoables
          assert_equal [@ids[1], @ids[2]], @manager.redoables
          
          id = @manager.push(new_item = @new_item_proc.call)
          
          assert_equal [id, @ids[0]], @manager.undoables
          assert_equal [], @manager.redoables
        end
      end
    end
  end
end
        