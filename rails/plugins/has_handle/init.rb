require 'ardes/has_handle'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::Handle }