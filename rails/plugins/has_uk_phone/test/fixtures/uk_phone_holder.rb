class UkPhoneHolder < ActiveRecord::Base
  has_uk_phone :required => true
  has_uk_phone :phone2
end