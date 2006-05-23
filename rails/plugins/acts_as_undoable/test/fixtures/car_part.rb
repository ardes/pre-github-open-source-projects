class CarPart < ActiveRecord::Base
  acts_as_undoable :car
  self.non_versioned_fields << 'position'
  belongs_to :car
end