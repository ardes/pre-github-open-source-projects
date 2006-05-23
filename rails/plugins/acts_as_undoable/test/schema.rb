require File.dirname(__FILE__) + '/fixtures/car'
require File.dirname(__FILE__) + '/fixtures/car_part'
require File.dirname(__FILE__) + '/fixtures/foo'

ActiveRecord::Schema.define(:version => 0) do
  create_table :cars, :force => true do |t|
    t.column "name", :string
    t.column "price", :integer
    t.column "version", :integer
  end

  create_table :car_parts, :force => true do |t|
    t.column "car_id", :integer
    t.column "name", :string
    t.column "position", :integer
    t.column "version", :integer
  end
  
  create_table :foos, :force => true do |t|
    t.column "name", :string
    t.column "version", :integer
  end
    
end

# create versioned tables
Car.create_versioned_table :force => true
CarPart.create_versioned_table :force => true
Foo.create_versioned_table :force => true

# create undo tables
Ardes::UndoManager.for(:car).create_undo_tables :force => true
Ardes::UndoManager.for(:foo).create_undo_tables :force => true