require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::Fact do
  it "should be defined with a name" do
    Schema::Fact.define(:sales).name.should == :sales
  end

  it "should have a table name" do
    Schema::Fact.define(:sales).table_name.should == :sales_facts
  end

  it "should set a primary key" do
    fact = Schema::Fact.define(:sales) do
      primary_key :product, :customer, :date
    end
    fact.primary_key.should == [:product, :customer, :date]
  end

  it "should return the dimension key id if the primary key includes a dimension" do
    fact = Schema::Fact.define(:sales) do
      primary_key :product, :customer, :date
      dimensions :product
    end
    fact.primary_key.should == [:product_dimension_id, :customer, :date]
  end

  it "should set a primary key with one column" do
    fact = Schema::Fact.define(:sales)
    fact.primary_key :product
    fact.dimensions :product

    fact.primary_key.should == :product_dimension_id
  end

  it "should set the dimensions for the fact" do
    fact = Schema::Fact.define(:sales) do
      dimensions :product, :customer
    end
    fact.dimension_names.should == [:product, :customer]
  end

  it "should allow dimensional roleplaying via a hash of name => dimension" do
    fact = Schema::Fact.define(:sales) do
      dimensions :product, :customer => :user
    end
    fact.dimension_names.should == [:product, :customer]
  end

  it "should know every defined fact" do
    Schema::Fact.clear_definitions
    Schema::Fact.define(:sales)
    Schema::Fact.define(:signups)
    Schema::Fact.definitions.size.should == 2
    Schema::Fact.definitions.map {|d| d.name }.should include(:sales)
    Schema::Fact.definitions.map {|d| d.name }.should include(:signups)
  end

  it "should not include fact definitions in its definitions" do
    Schema::Fact.clear_definitions
    Schema::Dimension.define(:user)
    Schema::Fact.definitions.should be_empty
  end

  it "should be able to clear previously defined dimensions with #clear_definitions" do
    Schema::Fact.define(:sales)
    Schema::Fact.clear_definitions
    Schema::Fact.definitions.should be_empty
  end
end

describe "Chicago::Fact#column_definitions" do
  it "should include the fact's dimension keys" do
    fact = Schema::Fact.define(:sales) do
      dimensions :product
    end
    fact.column_definitions.should include(Schema::Column.new(:product_dimension_id, :integer, :null => false, :min => 0))
  end

  it "should include the fact's degenerate_dimensions" do
    fact = Schema::Fact.define(:sales)
    fact.degenerate_dimensions do
      integer :order_number
    end

    fact.column_definitions.should include(Schema::Column.new(:order_number, :integer))
  end

  it "should include the fact's measures, which should allow null by default." do
    fact = Schema::Fact.define(:sales)
    fact.measures do
      integer :total
    end

    fact.column_definitions.should include(Schema::Column.new(:total, :integer, :null => true))
  end

  it "should be factless if there are no measures" do
    Schema::Fact.define(:sales).should be_factless
  end

  it "should not be factless if the dimension has measures" do
    Schema::Fact.define(:sales) { measures { integer :total } }.should_not be_factless
  end
end

describe "Chicago::Fact#db_schema" do
  before :each do 
    @fact = Schema::Fact.define(:sales)
    @tc = Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :generic))
  end

  it "should define a sales_facts table" do
    @fact.db_schema(@tc).keys.should include(:sales_facts)
  end

  it "should include a hash of table options" do
    @fact.db_schema(@tc)[:sales_facts][:table_options].should == {}
  end

  it "should have a table type of MyISAM for mysql" do
    @tc = Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :mysql))
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

  it "should define non-unique indexes for every dimension, except the first part of the primary key" do
    @fact.dimensions :foo, :bar
    @fact.primary_key :foo
    @fact.degenerate_dimensions { integer :baz }

    @fact.db_schema(@tc)[:sales_facts][:indexes].should == {
      :bar_idx => { :columns => :bar_dimension_id },
      :baz_idx => { :columns => :baz }
    }
  end
end