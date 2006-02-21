module ArdesTests
  module Abstract
    module Undo
      #
      # the setup_objects method should instantiate the following
      #   @item           # an undo item
      #   @undone_result  # the expected return value of on_undo
      #   @redone_result  # the expected return value of on_redo
      #
      module Item
        def setup
          setup_objects
        end
        
        def test_undo
          assert_equal @item.undo, @undone_result
          assert_equal @item.undone?, true 
          assert_raise(Ardes::Undo::ItemUndone) { @item.undo }
        end

        def test_redo
          assert_raise(Ardes::Undo::ItemNotUndone) { @item.redo }
          @item.undo
          assert_equal @item.redo, @redone_result
          assert_equal @item.undone?, false 
          assert_raise(Ardes::Undo::ItemNotUndone) { @item.redo }
        end
      end
    end
  end
end
