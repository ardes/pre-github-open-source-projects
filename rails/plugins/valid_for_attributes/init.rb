require 'ardes/valid_for_attributes'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::ValidForAttributes }