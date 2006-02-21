class AddUndoItems < ActiveRecord::Migration
  def self.up
    Ardes::ActiveRecord::Undo::Versioned::Manager.for(:things).stack.create_undo_table
  end
  
  def self.down
    Ardes::ActiveRecord::Undo::Versioned::Manager.for(:things).stack.drop_undo_table
  end
end