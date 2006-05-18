require 'ardes/aggregations_allow_nil'
ActiveRecord::Base.class_eval { include Ardes::ActiveRecord::AggregationsAllowNil }