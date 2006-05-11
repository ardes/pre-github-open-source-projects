ENV["RAILS_ENV"] = "test"
require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test_help'

load(File.dirname(__FILE__) + "/schema.rb")

class Test::Unit::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  
#  def create_fixtures(*table_names)
#    if block_given?
#      Fixtures.create_fixtures(self.fixture_path, table_names) { yield }
#    else
#      Fixtures.create_fixtures(self.fixture_path, table_names)
#    end
#  end
end