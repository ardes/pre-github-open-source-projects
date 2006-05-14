require File.dirname(__FILE__) + '/test_helper'
require 'uk_postcode'

class UKPostcodeTest < Test::Unit::TestCase
  
  def assert_uk_postcode_parts(postcode, area, district, sector, unit)
    assert_equal area,      postcode.area
    assert_equal district,  postcode.district
    assert_equal sector,    postcode.sector
    assert_equal unit,      postcode.unit
  end
  
  def test_should_remove_cruft_and_convert_to_upcase
    assert_equal 'S11 8BH', UkPostcode.new('   s11   8bh   ').to_s
  end
  
  def test_should_be_identicial_when_postcode_sane
    assert_equal 'S11 8BH', UkPostcode.new('S11 8BH').to_s
  end
  
  def test_should_split_S11_8BH_into_area_S_district_11_sector_8_unit_BH
    assert_uk_postcode_parts(UkPostcode.new('S11 8BH'), 'S', '11', '8', 'BH')
  end
  
  def test_should_split_SW1A_2AA_into_area_SW_district_1A_sector_2_unit_AA
    assert_uk_postcode_parts(UkPostcode.new('SW1A 2AA'), 'SW', '1A', '2', 'AA')
  end
  
  def test_should_validate_S11_8BH
    assert UkPostcode.new('S11 8BH').valid?
  end

  def test_should_validate_SW1A_2AA
    assert UkPostcode.new('SW1A 2AA').valid?
  end

  def test_should_not_validate_S111_2AA
    assert(!UkPostcode.new('S111 2AA').valid?)
  end
  
  def test_should_not_validate_S11_A2A
    assert(!UkPostcode.new('S11 A2A').valid?)
  end
  
  def test_should_validate_all_outcodes_and_split_into_area_and_district_from_uk_postcodes_data
    postcodes = File.open(File.dirname(__FILE__) + '/fixtures/uk_postcodes.csv')
    postcodes.readline # skip the column headings
    CSV::Reader.parse(postcodes) do |row|
      postcode = UkPostcode.new("#{row[0]} 1AA")
      assert postcode.valid?, "Postcode: #{row[0]} 1AA did not validate"
      assert_equal row[0], postcode.area + postcode.district
    end
  end
  
  def test_should_have_equality_for_objects_with_same_code
    assert_equal UkPostcode.new("S11 8BH"), UkPostcode.new("S11 8BH")
  end
  
  def test_should_have_equality_for_objects_with_same_code_including_cruft
    assert_equal UkPostcode.new("S11 8BH"), UkPostcode.new("   s11   8bh   ")
  end
end
