class EmailHolder < ActiveRecord::Base
  has_email :required => true
  has_email :email2
end