class Foo < ActiveRecord::Base
  acts_as_undoable :foo, :all
end