require 'ardes/has_email'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::Email }