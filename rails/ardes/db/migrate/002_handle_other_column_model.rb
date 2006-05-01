class HandleOtherColumnModel < ActiveRecord::Migration

  class HandleOtherColumnModel < ActiveRecord::Base; end
  
  def self.up
    create_table "handle_other_column_models" do |t|
      t.column "other", :string, :limit => 64
    end
  end
end