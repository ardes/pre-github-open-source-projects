# currently does not validate GIR 0AA, or Overeas Territories
# See http://en.wikipedia.org/wiki/UK_postcodes for details
class UkPostcode < ActiveRecord::Base
  acts_as_tableless do
    column :code, :string, :limit => 8, :default => '', :null => false
  end

  attr_reader :code
  
  validates_format_of :code, :if => :code,
    :with => /^(
        [A-PR-UWYZ]\d\d?\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ][A-HK-Y]\d\d?\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ]\d[A-PR-Z]\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ][A-HK-Y]\d[A-PR-Z]\s\d[ABD-HJLNP-UW-Z]{2}
      )$/x,
    :message => 'must be a valid UK postcode (not post office or overseas territories)'
  
  def initialize(code)
    @code = code.to_s.strip.split(" ").join(" ").upcase unless code.nil? 
  end
  
  def outcode
    @outcode or @outcode = @code.split(' ').first unless @code.nil?
  end
  
  def incode
    @incode or @incode = @code.split(' ').last unless @code.nil?
  end
  
  def area
    @area or @area = self.outcode.gsub(/\d\d?[A-Z]?$/, '') unless @code.nil?
  end
  
  def district
    @district or @district = self.outcode.gsub(/^[A-Z][A-Z]?/, '') unless @code.nil?
  end
  
  def sector
    @sector or @sector = self.incode.slice(0..0) unless @code.nil?
  end
  
  def unit
    @unit or @unit = self.incode.slice(1..2) unless @code.nil?
  end
  
  def to_s
    @code.to_s
  end
  
  def ==(other_postcode)
    @code == other_postcode.code
  end
  
  def empty?
    @code.nil?
  end
end