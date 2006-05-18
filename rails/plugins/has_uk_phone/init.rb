require 'ardes/has_uk_phone'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::UkPhone }