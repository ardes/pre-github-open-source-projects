ActiveRecord::Schema.define(:version => 0) do
  create_table :undo_items, :force => true do |t|
    t.column :undone, :boolean, :null => false, :default => false
  end

  create_table :undo_versioned_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string
    t.column :created_at, :timestamp
  end

  create_table :undo_versioned_grouping_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :description, :string
    t.column :created_at, :timestamp
  end
  
  create_table :undo_versioned_grouping_item_atoms, :force => true do |t|
    t.column :undo_versioned_grouping_item_id, :integer
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string
  end

  #
  # Tables for undo_versioned_test
  #
  create_table :v_fine_products, :force => true do |t|
    t.column :name, :string
    t.column :version, :integer
  end
  
  create_table :v_fine_product_versions, :force => true do |t|
    t.column :v_fine_product_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end
  
  create_table :v_fine_product_parts, :force => true do |t|
    t.column :name, :string
    t.column :v_fine_product_id, :integer
    t.column :version, :integer
  end

  create_table :v_fine_product_part_versions, :force => true do |t|
    t.column :v_fine_product_part_id, :integer
    t.column :version, :integer
    t.column :v_fine_product_id, :integer
    t.column :name, :string
  end

  create_table :v_product_undo_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string, :null => true
    t.column :created_at, :timestamp
  end

  #
  # Tables for undo_versioned_grouping_test
  #
  create_table :g_fine_products, :force => true do |t|
    t.column :name, :string
    t.column :version, :integer
  end
  
  create_table :g_fine_product_versions, :force => true do |t|
    t.column :g_fine_product_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end
  
  create_table :g_fine_product_parts, :force => true do |t|
    t.column :name, :string
    t.column :g_fine_product_id, :integer
    t.column :version, :integer
  end

  create_table :g_fine_product_part_versions, :force => true do |t|
    t.column :g_fine_product_part_id, :integer
    t.column :version, :integer
    t.column :g_fine_product_id, :integer
    t.column :name, :string
  end

  create_table :g_product_undo_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :description, :string, :null => true
    t.column :created_at, :timestamp
  end
  
  create_table :g_product_undo_item_atoms, :force => true do |t|
    t.column :g_product_undo_item_id, :integer
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string
  end
  
  #
  # Tables for active_record_acts_undo_test
  #
  create_table :vehicles, :force => true do |t|
    t.column :version, :integer
    t.column :name, :string
  end

  create_table :vehicle_versions, :force => true do |t|
    t.column :vehicle_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end
  
  create_table :parts, :force => true do |t|
    t.column :vehicle_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end

  create_table :part_versions, :force => true do |t|
    t.column :part_id, :integer
    t.column :vehicle_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end
  
  create_table :vehicle_undo_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :description, :string, :null => true
    t.column :created_at, :timestamp
  end
  
  create_table :vehicle_undo_item_atoms, :force => true do |t|
    t.column :vehicle_undo_item_id, :integer
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string
  end
    
end