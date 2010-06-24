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

  it "should allow dimensional roleplaying via a hash of name => dimension" do
    fact = Fact.define(:sales) do
      dimensions :product, :customer => :user
    end
    fact.dimension_names.should == [:product, :customer]
  end

  it "should know every defined fact" do
    Fact.clear_definitions
    Fact.define(:sales)
    Fact.define(:signups)
    Fact.definitions.size.should == 2
    Fact.definitions.map {|d| d.name }.should include(:sales)
    Fact.definitions.map {|d| d.name }.should include(:signups)
  end

  it "should not include fact definitions in its definitions" do
    Fact.clear_definitions
    Dimension.define(:user)
    Fact.definitions.should be_empty
  end

  it "should be able to clear previously defined dimensions with #clear_definitions" do
    Fact.define(:sales)
    Fact.clear_definitions
    Fact.definitions.should be_empty
  end
end

describe "Chicago::Fact#column_definitions" do
  it "should include the fact's dimension keys" do
    fact = Fact.define(:sales) do
      dimensions :product
    end
    fact.column_definitions.should include(Column.new(:product_dimension_id, :integer, :null => false, :min => 0))
  end

  it "should include the fact's degenerate_dimensions" do
    fact = Fact.define(:sales)
    fact.degenerate_dimensions do
      integer :order_number
    end

    fact.column_definitions.should include(Column.new(:order_number, :integer))
  end

  it "should include the fact's measures, which should allow null by default." do
    fact = Fact.define(:sales)
    fact.measures do
      integer :total
    end

    fact.column_definitions.should include(Column.new(:total, :integer, :null => true))
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

  it "should output the dimension foreign key columns" do
    @fact.dimensions :customer, :product

    [{:name => :customer_dimension_id, :column_type => :integer, :unsigned => true, :null => false},
     {:name => :product_dimension_id, :column_type => :integer, :unsigned => true, :null => false}
    ].each do |column|
      @fact.db_schema(@tc)[:sales_facts][:columns].should include(column)
    end
  end

  it "should output the degenerate dimension columns" do
    @fact.degenerate_dimensions do
      string :reference
    end

    @fact.db_schema(@tc)[:sales_facts][:columns].should include({:name => :reference, :column_type => :varchar, :null => false})
  end

  it "should output the measure columns" do
    @fact.measures do
      integer :quantity
    end

    @fact.db_schema(@tc)[:sales_facts][:columns].should include({:name => :quantity, :column_type => :integer, :null => true, :unsigned => false})
  end
end
