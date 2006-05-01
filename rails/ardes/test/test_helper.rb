ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test/rails'
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/lib/init.rb")

class Test::Rails::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end