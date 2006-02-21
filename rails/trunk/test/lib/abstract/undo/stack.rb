module Test
  module Abstract
    module Undo
      #
      # the setup_objects method should instantiate the following
      #   @stack          # an undo stack
      #   @new_item_proc  # proc that returns a new item
      # 
      module Stack
        
        def setup
          setup_objects          
          @ids = (0..3).collect {@stack.push_item(@new_item_proc.call)}
        end
        
        # Test that equivalent ways of calling items are in fact equivalent
        def test_items_args
          # undo an item to make the test more reliable
          @stack.item_at(@ids[3]) {|item| item.undo}
          
          assert_equal @stack.item_ids,        @stack.item_ids(nil, :all)
          assert_equal @stack.item_ids(true),  @stack.item_ids(:undone)
          assert_equal @stack.item_ids(false), @stack.item_ids(:not_undone)
        end

        # Test the return ordering of calls to items
        def test_items_ordering
          # unspecified items shoudl be returned in ascending order
          # undone items should be retured in ascending order
          # not_undone items should be returned in descending order
          
          # undo last two items, so [0 not undone, 1 not undone, 2 undone, 3 undone ]
          @stack.item_at(@ids[3]) {|item| item.undo}
          @stack.item_at(@ids[2]) {|item| item.undo}
          
          # Test all items returned in asc order
          assert_equal @ids, @stack.item_ids
          
          # Test :first
          assert_equal [@ids[1]], @stack.item_ids(:not_undone, :first)
          assert_equal [@ids[2]], @stack.item_ids(:undone,     :first)
          
          # Test :all
          assert_equal [@ids[1], @ids[0]], @stack.item_ids(:not_undone, :all)
          assert_equal [@ids[2], @ids[3]], @stack.item_ids(:undone,     :all)

          # Test with to = some_id, it should return array of items 'up to' that id
          assert_equal [@ids[1], @ids[0]], @stack.item_ids(:not_undone, @ids[0])
          assert_equal [@ids[1]],          @stack.item_ids(:not_undone, @ids[1])
          
          assert_equal [@ids[2]],          @stack.item_ids(:undone,     @ids[2])
          assert_equal [@ids[2], @ids[3]], @stack.item_ids(:undone,     @ids[3])
          
          # undo the rest of the items
          @stack.item_at(@ids[1]) {|item| item.undo}
          @stack.item_at(@ids[0]) {|item| item.undo}
          
          # test :all
          assert_equal [],   @stack.item_ids(:not_undone)
          assert_equal @ids, @stack.item_ids(:undone)
          
          # redo the entire stack
          (0..3).each {|i| @stack.item_at(@ids[i]) {|item| item.redo} }
          
          # test :all
          assert_equal @ids.reverse, @stack.item_ids(:not_undone)
          assert_equal [],           @stack.item_ids(:undone)
        end
        
        def test_delete_undone_items
          @stack.item_at(@ids[3]) {|item| item.undo}
          @stack.item_at(@ids[2]) {|item| item.undo}
          @stack.delete_undone_items
          assert_equal [@ids[0], @ids[1]], @stack.item_ids
        end
        
        def test_push_item
          new_id = @stack.push_item(@new_item_proc.call)
          assert_equal @ids << new_id, @stack.item_ids
        end
        
        def test_each_id_item
          result = Array.new
          @stack.each_id_item {|id,item| result << id}
          assert_equal @ids, result
          result = Array.new
          @stack.each_id_item(:reverse) {|id,item| result << id}
          assert_equal @ids.reverse, result
        end
      end
    end
  end
end