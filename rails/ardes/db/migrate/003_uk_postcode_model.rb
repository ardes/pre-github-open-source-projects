class UkPostcodeModel < ActiveRecord::Migration

  class UkPostcodeModel < ActiveRecord::Base; end
  
  def self.up
    create_table "uk_postcode_models" do |t|
      t.column "postcode", :string, :limit => 10
      t.column "postcode2", :string, :limit => 10
    end
  end
end