require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Fact do
  it "should be defined with a name" do
    Fact.define(:sales).name.should == :sales
  end

  it "should have a table name" do
    Fact.define(:sales).table_name.should == :sales_facts
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    fact = Fact.define(:sales) do
      columns { string :username }
    end

    fact.column_definitions.should == [column]
  end
end

describe "Chicago::Fact#db_schema" do
  before :each do 
    @fact = Fact.define(:sales)
    @tc = Chicago::Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :generic))
  end

  it "should define a sales_facts table" do
    @fact.db_schema(@tc).keys.should include(:sales_facts)
  end

  it "should include a hash of table options" do
    @fact.db_schema(@tc)[:sales_facts][:table_options].should == {}
  end

  it "should have a table type of MyISAM for mysql" do
    @tc = Chicago::Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :mysql))
    @fact.db_schema(@tc)[:sales_facts][:table_options].should == {:engine => "myisam"}
  end

  it "should include the sequel schema for the defined columns" do
    @fact.columns do
      integer :total, :min => 0
    end

    expected = {:name => :total, :column_type => :integer, :null => false, :unsigned => true}
    @fact.db_schema(@tc)[:sales_facts][:columns].should include(expected)
  end
end
