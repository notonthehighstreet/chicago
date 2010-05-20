require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::DimensionDefinition do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should be constructed with a dimension name" do
    DimensionDefinition.new(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    DimensionDefinition.new('user').name.should == :user
  end

  it "should create a column definition" do
    ColumnDefinition.should_receive(:new).with(@column_attributes)
    dd = DimensionDefinition.new('user')
    dd.define_column :type => :varchar, :name => :username
  end

  it "should support arbitrary column definitions as methods" do
    ColumnDefinition.should_receive(:new).with(@column_attributes)
    DimensionDefinition.new(:user).varchar :username

    ColumnDefinition.should_receive(:new).with(:type => :money, :name => :fee)
    DimensionDefinition.new(:user).money :fee
  end

  it "should return a list of defined columns" do
    stubbed_definition = stub()
    ColumnDefinition.should_receive(:new).with(@column_attributes).and_return(stubbed_definition)
    dd = DimensionDefinition.new(:user)
    dd.varchar :username
    dd.column_definitions.should include(stubbed_definition)
  end

  it "should accept a column definition instead of a hash" do
    definition = ColumnDefinition.new(@column_attributes)
    dd = DimensionDefinition.new(:user)
    dd.define_column definition
    dd.column_definitions.should include(definition)
  end
end
