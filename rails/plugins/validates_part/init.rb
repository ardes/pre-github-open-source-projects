require 'ardes/validates_part'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::ValidatesPart }