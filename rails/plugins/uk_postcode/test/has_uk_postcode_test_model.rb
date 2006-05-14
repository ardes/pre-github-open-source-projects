class HasUkPostcodeTestModel < ActiveRecord::Base
  has_uk_postcode :postcode, :required => true
  has_uk_postcode :postcode2
end