class UkPostcodeModel < ActiveRecord::Base
  has_uk_postcode :postcode, :postcode2
end