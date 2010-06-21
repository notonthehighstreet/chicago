require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Dimension do
  it "should be constructed with a dimension name" do
    Dimension.define(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    Dimension.define('user').name.should == :user
  end

  it "should have a table name" do
    Dimension.define(:user).table_name.should == :user_dimension
  end

  it "should know every defined dimension" do
    Dimension.clear_definitions
    Dimension.define(:user)
    Dimension.define(:product)
    Dimension.definitions.size.should == 2
    Dimension.definitions.map {|d| d.name }.should include(:user)
    Dimension.definitions.map {|d| d.name }.should include(:product)
  end

  it "should not include fact definitions in its definitions" do
    Dimension.clear_definitions
    Fact.define(:sales)
    Dimension.definitions.should be_empty
  end

  it "should be able to clear previously defined dimensions with #clear_definitions" do
    Dimension.define(:user)
    Dimension.clear_definitions
    Dimension.definitions.should be_empty
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    dd = Dimension.define(:user) do
      columns { string :username }
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
    @tc = Chicago::Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :generic))
  end

  it "should define a user_dimension table" do
    @dimension.db_schema(@tc).keys.should include(:user_dimension)
  end

  it "should have an unsigned integer :id column" do
    expected = {:name => :id, :column_type => :integer, :unsigned => true}
    @dimension.db_schema(@tc)[:user_dimension][:columns].should include(expected)
  end

  it "should define :id as the primary key" do
    @dimension.db_schema(@tc)[:user_dimension][:primary_key].should == :id
  end

  it "should include a hash of table options" do
    @dimension.db_schema(@tc)[:user_dimension][:table_options].should == {}
  end

  it "should have a table type of MyISAM for mysql" do
    @tc = Chicago::Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :mysql))
    @dimension.db_schema(@tc)[:user_dimension][:table_options].should == {:engine => "myisam"}
  end

  it "should include the sequel schema for the defined columns" do
    @dimension.columns do
      string :username, :max => 10
    end

    expected = {:name => :username, :column_type => :varchar, :size => 10, :null => false}
    @dimension.db_schema(@tc)[:user_dimension][:columns].should include(expected)
  end
end
