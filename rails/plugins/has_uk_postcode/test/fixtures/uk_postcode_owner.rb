class UkPostcodeOwner < ActiveRecord::Base
  has_uk_postcode :required => true
  has_uk_postcode :postcode2
end