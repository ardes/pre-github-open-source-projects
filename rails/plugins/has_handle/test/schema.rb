ActiveRecord::Schema.define(:version => 0) do
  create_table :handle_models, :force => true do |t|
    t.column :handle, :string, :limit => 64
  end
  
  create_table :handle_other_column_models, :force => true do |t|
    t.column :other, :string, :limit => 64
  end
end