ActiveRecord::Schema.define(:version => 0) do
  create_table :uk_postcode_owners, :force => true do |t|
    t.column "postcode", :string, :limit => 8
    t.column "postcode2", :string, :limit => 8
  end
end