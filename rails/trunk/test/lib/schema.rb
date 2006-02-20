ActiveRecord::Schema.define(:version => 0) do
  create_table :undo_items, :force => true do |t|
    t.column :undone, :boolean, :null => false, :default => false
  end

  create_table :undo_versioned_items, :force => true do |t|
    t.column :undone, :boolean, :default => false, :null => false
    t.column :obj_class_name, :string, :null => false
    t.column :obj_id, :int, :null => false
    t.column :down_version, :int, :null => true
    t.column :up_version, :int, :null => true
  end

end