require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Fact do
  it "should be defined with a name" do
    Fact.define(:sales).name.should == :sales
  end

  it "should have a table name" do
    Fact.define(:sales).table_name.should == :sales_facts
  end

  it "should set a primary key" do
    fact = Fact.define(:sales) do
      primary_key :product, :customer, :date
    end
    fact.primary_key.should == [:product, :customer, :date]
  end

  it "should return the dimension key id if the primary key includes a dimension" do
    fact = Fact.define(:sales) do
      primary_key :product, :customer, :date
      dimensions :product
    end
    fact.primary_key.should == [:product_dimension_id, :customer, :date]
  end

  it "should set the dimensions for the fact" do
    fact = Fact.define(:sales) do
      dimensions :product, :customer
    end
    fact.dimension_names.should == [:product, :customer]
  end
end

describe "Chicago::Fact#column_definitions" do
  it "should include the fact's dimension keys" do
    fact = Fact.define(:sales) do
      dimensions :product
    end
    fact.column_definitions.should include(ColumnDefinition.new(:product_dimension_id, :integer, :null => false, :min => 0))
  end

  it "should include the fact's degenerate_dimensions" do
    fact = Fact.define(:sales)
    fact.degenerate_dimensions do
      integer :order_number
    end

    fact.column_definitions.should include(ColumnDefinition.new(:order_number, :integer))
  end

  it "should include the fact's measures" do
    fact = Fact.define(:sales)
    fact.measures do
      integer :total
    end

    fact.column_definitions.should include(ColumnDefinition.new(:total, :integer))
  end

  it "should be factless if there are no measures" do
    Fact.define(:sales).should be_factless
  end

  it "should not be factless if the dimension has measures" do
    Fact.define(:sales) { measures { integer :total } }.should_not be_factless
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

  it "should output the primary key" do
    @fact.primary_key :foo, :bar
    @fact.db_schema(@tc)[:sales_facts][:primary_key].should == [:foo, :bar]
  end
end
