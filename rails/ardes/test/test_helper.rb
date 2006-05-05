ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test/rails'
require 'test_help'

module Ardes; end# :nodoc:
module Ardes::TestCase; end# :nodoc:
  
class Test::Rails::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end
