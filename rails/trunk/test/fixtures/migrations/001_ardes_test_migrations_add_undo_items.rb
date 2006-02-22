class ArdesTestMigrationsAddUndoItems < ActiveRecord::Migration
  def self.up
    Ardes::Undo::Versioned::Manager.for(:things).stack.create_table
  end
  
  def self.down
    Ardes::Undo::Versioned::Manager.for(:things).stack.drop_table
  end
end