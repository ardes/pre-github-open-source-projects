require 'active_record'

config = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/../test.log")
ActiveRecord::Base.establish_connection(config['test'])
load(File.dirname(__FILE__) + "/schema.rb")