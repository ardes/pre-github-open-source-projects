ENV["RAILS_ENV"] = "test"
require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '../../../../config/environment.rb'))
require 'test_help'

load(File.dirname(__FILE__) + "/schema.rb")

class Test::Unit::TestCase
  self.use_transactional_fixtures = false
  self.use_instantiated_fixtures  = false
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end