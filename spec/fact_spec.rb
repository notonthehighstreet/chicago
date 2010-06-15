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

  it "should set the dimensions for the fact" do
    fact = Fact.define(:sales) do
      dimensions :product, :customer
    end
    fact.dimension_names.should == [:product, :customer]
  end

  it "should set the degenerate dimensions for the fact" do
    fact = Fact.define(:sales) do
      degenerate_dimensions do
        integer :order_number
      end
    end
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
