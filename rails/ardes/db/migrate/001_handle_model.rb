class HandleModel < ActiveRecord::Migration

  class HandleModel < ActiveRecord::Base; end
  
  def self.up
    create_table "handle_models" do |t|
      t.column "handle", :string, :limit => 64
    end
  end
end