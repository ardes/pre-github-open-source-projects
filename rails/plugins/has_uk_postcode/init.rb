require 'ardes/has_uk_postcode'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::Has::UkPostcode }