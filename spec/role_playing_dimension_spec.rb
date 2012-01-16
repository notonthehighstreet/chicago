require 'spec_helper'

describe Chicago::RolePlayingDimension do
  before :each do
    @column = stub(:column, :name => :quux)
    @base_dimension = Chicago::Dimension.new(:foo, :columns => [@column])
    @dimension = Chicago::RolePlayingDimension.new(:bar, @base_dimension)
  end

  it "should have the role-played name" do
    @dimension.name.should == :bar
  end

  it "should have the role-played label" do
    @dimension.label.should == "Bar"
  end
  
  it "should qualify the column based on the aliased name" do
    @dimension.qualify(stub(:column, :name => :baz)).
      should == :baz.qualify(:dimension_bar)
  end

  it "should have an aliased table name" do
    @dimension.table_name.should == :dimension_foo.as(:dimension_bar)
  end

  it "should delegate column access to the underlying dimension" do
    @dimension[:quux].should == @column
  end
end
