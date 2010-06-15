require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Dimension do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should be constructed with a dimension name" do
    Dimension.define(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    Dimension.define('user').name.should == :user
  end

  it "should have a table name" do
    Dimension.define(:user).table_name.should == :user_dimension
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    dd = Dimension.define(:user) do
      columns { varchar :username }
    end

    dd.column_definitions.should == [column]
  end

  it "should specify a main identifier column" do
    Dimension.define(:user) { identified_by :username }.main_identifier.should == :username
  end

  it "should allow additional identifying columns" do
    dimension = Dimension.define(:user) { identified_by :username, :and => [:email] }

    dimension.main_identifier.should == :username
    dimension.identifiers.should == [:username, :email]
  end
end

describe "Chicago::Dimension#db_schema" do
  before :each do 
    @dimension = Dimension.define(:user)
    @db = mock(:database)
  end

  it "should define a user_dimension table" do
    @dimension.db_schema(@db).keys.should include(:user_dimension)
  end

  it "should have an unsigned integer :id column" do
    expected = {:name => :id, :column_type => :integer, :unsigned => true}
    @dimension.db_schema(@db)[:user_dimension][:columns].should include(expected)
  end

  it "should define :id as the primary key" do
    @dimension.db_schema(@db)[:user_dimension][:primary_key].should == :id
  end

  it "should include the sequel schema for the defined columns" do
    @db.should_receive(:database_type).and_return(:mysql)

    @dimension.columns do
      string :username, :max => 10
    end

    expected = {:name => :username, :column_type => :varchar, :size => 10, :null => false}
    @dimension.db_schema(@db)[:user_dimension][:columns].should include(expected)
  end
end
