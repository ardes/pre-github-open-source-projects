class ActiveRecord::Base
  def valid_for_attributes?(*attrs)
    attrs = attrs.collect {|a| a.to_s}
    unless self.valid?
      errors = self.errors
      attr_errors = Array.new
      errors.each {|a,err| attr_errors << [a,err] if attrs.include?(a)}
      errors.clear
      attr_errors.each {|a,err| errors.add(a,err)}
      return false unless errors.empty?
    end
    return true
  end
end
