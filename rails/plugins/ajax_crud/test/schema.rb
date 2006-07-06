ActiveRecord::Schema.define(:version => 0) do
  create_table :ajax_crud_models, :force => true do |t|
    t.column "name", :string
  end
end