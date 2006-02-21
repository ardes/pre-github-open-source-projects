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
  end
    
  create_table :fine_products, :force => true do |t|
    t.column :name, :string
    t.column :version, :integer
  end
  
  create_table :fine_product_versions, :force => true do |t|
    t.column :fine_product_id, :integer
    t.column :version, :integer
    t.column :name, :string
  end
  
  create_table :fine_product_parts, :force => true do |t|
    t.column :name, :string
    t.column :fine_product_id, :integer
    t.column :version, :integer
  end

  create_table :fine_product_part_versions, :force => true do |t|
    t.column :fine_product_part_id, :integer
    t.column :version, :integer
    t.column :fine_product_id, :integer
    t.column :name, :string
  end


  create_table :product_undo_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :integer, :null => false
    t.column :down_version, :integer, :null => true
    t.column :up_version, :integer, :null => true
    t.column :obj_description, :string, :null => true
  end
end