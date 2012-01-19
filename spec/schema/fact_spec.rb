require "spec_helper"

describe Chicago::Schema::Fact do
  it "should be defined with a name" do
    Schema::Fact.define(:sales).name.should == :sales
  end

  it "has a human-friendly label" do
    Schema::Fact.define(:monthly_sales).label.should == "Monthly Sales"
  end

  it "should have a table name" do
    Schema::Fact.define(:sales).table_name.should == :facts_sales
  end

  it "should set the dimensions for the fact" do
    Schema::Dimension.define(:product)
    Schema::Dimension.define(:customer)
    fact = Schema::Fact.define(:sales) do
      dimensions :product, :customer
    end
    fact.dimension_names.should == [:product, :customer]
  end

  it "should allow dimensional roleplaying via a hash of name => dimension" do
    Schema::Dimension.define(:product)
    Schema::Dimension.define(:user)
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
