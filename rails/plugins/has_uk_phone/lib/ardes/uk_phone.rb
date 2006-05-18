require 'ardes/validatable'

module Ardes
  # validates uk phone number including mobiles and optional +44 prefix
  class UkPhone
    include Ardes::Validatable
  
    attr_reader :number
  
    validates_format_of :number,
      :with => /^(\+44\s?[1-9]|0[1-9])(\d\s?){9}$/,
      :message => 'must be a valid UK phone number'
  
    def initialize(number)
      @number = number.to_s.strip.gsub(/[\(\)]/, '').split(" ").join(" ") unless number.nil? 
    end

    def to_s
      @number.to_s
    end
  
    def ==(other_phone)
      self.canonical == other_phone.canonical
    end
  
    def canonical
      @number.gsub(' ', '').gsub('+44', '0') unless @number.nil?
    end
  
    def empty?
      @number.nil?
    end
  end
end