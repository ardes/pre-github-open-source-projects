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
          @items = (0..2).collect {@new_item_proc.call}
          @ids = @items.collect {|item| @manager.push(item)}
        end
        
        def test_manager
          @manager.undo :all
          assert_equal [true, true, true], [@items[0].undone?, @items[1].undone?, @items[2].undone?]
          assert_equal [], @manager.undo(:first)
          
          assert_equal [ [@ids[0], @items[0]] ], @manager.redo
          assert_equal [false, true, true], [@items[0].undone?, @items[1].undone?, @items[2].undone?]
          
          @manager.redo :all
          assert_equal [false, false, false], [@items[0].undone?, @items[1].undone?, @items[2].undone?]
          
          assert_equal [ [@ids[2], @items[2]], [@ids[1], @items[1]] ], @manager.undo(@ids[1])
          
          assert_equal [false, true, true], [@items[0].undone?, @items[1].undone?, @items[2].undone?]
          
          @manager.redo
          
          assert_equal [ [@ids[1],@items[1]], [@ids[0],@items[0]] ], @manager.undoables
          assert_equal [ [@ids[2],@items[2]] ], @manager.redoables
          
          @manager.undo

          assert_equal [ [@ids[0],@items[0]] ], @manager.undoables
          assert_equal [ [@ids[1],@items[1]], [@ids[2],@items[2]] ], @manager.redoables
          
          id = @manager.push(new_item = @new_item_proc.call)
          
          assert_equal [ [id,new_item], [@ids[0],@items[0]] ], @manager.undoables
          assert_equal [], @manager.redoables
        end
      end
    end
  end
end
        