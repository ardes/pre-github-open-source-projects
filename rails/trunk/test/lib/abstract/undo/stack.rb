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
          (0..3).each {@stack.push_item(@new_item_proc.call)}
          @items = Array.new
          @ids = Array.new
          @stack.each_item {|id,item| @ids << id; @items << item}
        end
        
        def all_items_with_id
          (0..3).collect {|i| [@ids[i], @items[i]]}
        end
        
        # Test that equivalent ways of calling items are in fact equivalent
        def test_items_args
          # undo an item to make the test more reliable
          @items[3].undo
          
          assert_equal @stack.items,          @stack.items(nil, :all)
          assert_equal @stack.items(true),    @stack.items(:undone)
          assert_equal @stack.items(false),   @stack.items(:not_undone)
        end

        # Test the return ordering of calls to items
        def test_items_ordering
          # unspecified items shoudl be returned in ascending order
          # undone items should be retured in ascending order
          # not_undone items should be returned in descending order
          
          # undo last two items, so [0 not undone, 1 not undone, 2 undone, 3 undone ]
          @items[3].undo
          @stack.update_item @ids[3], @items[3]
          @items[2].undo
          @stack.update_item @ids[2], @items[2]
          
          # Test all items returned in asc order
          assert_equal @stack.items, all_items_with_id
          
          # Test :first
          assert_equal [ [@ids[1], @items[1]] ], @stack.items(:not_undone, :first)
          assert_equal [ [@ids[2], @items[2]] ], @stack.items(:undone,     :first)
          
          # Test :all
          assert_equal [ [@ids[1], @items[1]], [@ids[0], @items[0]] ], @stack.items(:not_undone, :all)
          assert_equal [ [@ids[2], @items[2]], [@ids[3], @items[3]] ], @stack.items(:undone,     :all)

          # Test with to = some_id, it should return array of items 'up to' that id
          assert_equal [ [@ids[1], @items[1]], [@ids[0], @items[0]] ], @stack.items(:not_undone, @ids[0])
          assert_equal [ [@ids[1], @items[1]] ],                       @stack.items(:not_undone, @ids[1])
          
          assert_equal [ [@ids[2], @items[2]] ],                       @stack.items(:undone,     @ids[2])
          assert_equal [ [@ids[2], @items[2]], [@ids[3], @items[3]] ], @stack.items(:undone,     @ids[3])
          
          # undo the rest of the items
          @items[1].undo
          @stack.update_item @ids[1], @items[1]
          @items[0].undo
          @stack.update_item @ids[0], @items[0]
          
          # test :all
          assert_equal [],                @stack.items(:not_undone)
          assert_equal all_items_with_id, @stack.items(:undone)
          
          # redo the entire stack
          (0..3).each {|i| @items[i].redo; @stack.update_item @ids[i], @items[i] }
          
          # test :all
          assert_equal all_items_with_id.reverse, @stack.items(:not_undone)
          assert_equal [],                        @stack.items(:undone)
        end
        
        def test_delete_undone_items
          @items[3].undo
          @stack.update_item @ids[3], @items[3]
          @items[2].undo
          @stack.update_item @ids[2], @items[2]
          @stack.delete_undone_items
          assert_equal [ [@ids[0], @items[0]], [@ids[1], @items[1]] ], @stack.items
        end
        
        def test_update_item
          new_item = @new_item_proc.call
          new_item.undo
          assert_equal @ids[3], @stack.items(:not_undone, :first)[0][0]
          @stack.update_item @ids[3], new_item
          assert_equal @ids[3], @stack.items(:undone, :first)[0][0]
        end
        
        def test_push_item
          id = @stack.push_item(new_item = @new_item_proc.call)
          assert_equal @stack.items, all_items_with_id << [id, new_item]
        end
        
        def test_each_item
          result = Array.new
          @stack.each_item {|id,item| result << [id,item]}
          assert_equal all_items_with_id, result
          result = Array.new
          @stack.each_item(:reverse) {|id,item| result << [id,item]}
          assert_equal all_items_with_id.reverse, result
        end
      end
    end
  end
end