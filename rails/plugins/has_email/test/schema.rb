ActiveRecord::Schema.define(:version => 0) do
  create_table :email_holders, :force => true do |t|
    t.column "email", :string
    t.column "email2", :string
  end
end