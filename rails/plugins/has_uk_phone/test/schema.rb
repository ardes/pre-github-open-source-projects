ActiveRecord::Schema.define(:version => 0) do
  create_table :uk_phone_holders, :force => true do |t|
    t.column "phone", :string, :limit => 20
    t.column "phone2", :string, :limit => 20
  end
end