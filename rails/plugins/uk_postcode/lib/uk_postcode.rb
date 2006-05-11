# currently does not validate GIR 0AA, or Overeas Territories
# See http://en.wikipedia.org/wiki/UK_postcodes for details
class UkPostcode < ActiveRecord::Base
  acts_as_tableless do
    column :code, :string, :limit => 8, :default => '', :null => false
  end
  
  attr_reader :code
  
  validates_format_of :code,
    :with => /^(
        [A-PR-UWYZ]\d\d?\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ][A-HK-Y]\d\d?\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ]\d[A-PR-Z]\s\d[ABD-HJLNP-UW-Z]{2}
      | [A-PR-UWYZ][A-HK-Y]\d[A-PR-Z]\s\d[ABD-HJLNP-UW-Z]{2}
      )$/x,
    :message => 'must be a valid UK postcode (not post office or overseas territories)'
  
  def initialize(code)
    @code = code.to_s.strip.split(" ").join(" ").upcase
  end
  
  def outcode; @outcode or @outcode = @code.split(' ').first; end
  
  def incode; @incode or @incode = @code.split(' ').last; end
  
  def area; @area or @area = self.outcode.gsub(/\d\d?[A-Z]?$/, ''); end
  
  def district; @district or @district = self.outcode.gsub(/^[A-Z][A-Z]?/, ''); end
  
  def sector; @sector or @sector = self.incode.slice(0..0); end
  
  def unit; @unit or @unit = self.incode.slice(1..2); end
  
  def to_s; @code; end
  
  def ==(other_postcode)
    @code == other_postcode.code
  end
end