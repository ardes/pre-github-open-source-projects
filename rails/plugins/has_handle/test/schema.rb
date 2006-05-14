ActiveRecord::Schema.define(:version => 0) do
  create_table :has_handle_test_models, :force => true do |t|
    t.column :handle, :string, :limit => 64
  end
  
  create_table :has_handle_other_column_test_models, :force => true do |t|
    t.column :other, :string, :limit => 64
  end
end