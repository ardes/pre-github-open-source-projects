require 'ardes/acts_as_undoable'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Acts::Undo }