class ActsAsTablelessTest < Test::Unit::TestCase
            def test_should_have_attributes_corresponding_to_columns
              obj = self.acts_as_tableless_class.new
              assert_equal obj.attributes.keys.sort, obj.class.columns.collect{|c| c.name}.sort
            end
    
            def test_should_make_new_object_on_create
              assert_kind_of self.acts_as_tableless_class, self.acts_as_tableless_class.create
            end
    
            def test_should_make_object_corresponding_to_attributes_on_update_attributes
              obj = self.acts_as_tableless_class.new
              attr = obj.attributes.keys.first
              obj.update_attributes(attr => '1')
              assert_equal '1', obj.attributes[attr].to_s
            end
    
            def test_should_not_raise_error_on_save
              self.acts_as_tableless_class.new.save
            end
          end
        end
      end
    end
  end
end

class NoTable < ActiveRecord::Base
  acts_as_tableless do
    column :age, :integer, :null => true
    column :name, :string, :limit => 20, :default => 'anonymous'
    column :rating, :integer, :null => false, :default => 10
  end

  validates_presence_of :age
end

class InitWithColumnNamesNoTable < ActiveRecord::Base
  acts_as_tableless :name, :age
end

class Ardes::TestCase::ActsAsTablelessNoTable < Test::Rails::TestCase
  test_acts_as_tableless :no_table
  
  def test_should_have_defaults_correpsonding_to_column_definition
    obj = NoTable.new
    assert_equal 'anonymous', obj.name
    assert_equal 10, obj.rating
    assert_equal nil, obj.age
  end

  def test_should_have_types_corresponding_to_column_definition
    obj = NoTable.new
    assert_kind_of String, obj.name
    assert_kind_of Integer, obj.rating
    assert_kind_of NilClass, obj.age
  end
  
  def test_should_allow_validation
    obj = NoTable.new
    deny obj.valid?
    obj.age = 20
    assert obj.valid?
  end
end

#=============


class Ardes::TestCase::ActsAsTablelessInitWithColumnNamesNoTable < Test::Rails::TestCase
  test_acts_as_tableless :init_with_column_names_no_table
  
  def test_should_accept_values_when_initialized_with_column_names_only
    obj = InitWithColumnNamesNoTable.new
    obj.name = 'frank'
    obj.age = 20
    assert_equal 'frank', obj.name
    assert_equal 20, obj.age
  end
end
