class Car < ActiveRecord::Base
  acts_as_undoable :car
  has_many :car_parts, :dependent => true
end