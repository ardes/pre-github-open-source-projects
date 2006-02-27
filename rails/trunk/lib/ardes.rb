$:.unshift File.join(File.dirname(__FILE__))

require 'ardes/active_record/validations'
require 'ardes/active_record/acts/undo'
require 'ardes/action_controller/acts/undo'