require 'ardes/acts_as_tableless'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Acts::Tableless }