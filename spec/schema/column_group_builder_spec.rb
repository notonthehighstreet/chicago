require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::ColumnGroupBuilder do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should create a column definition" do
    ColumnDefinition.should_receive(:new).with(@column_attributes)
    Schema::ColumnGroupBuilder.new.column :type => :varchar, :name => :username
  end

  it "should support arbitrary column definitions as methods" do
    ColumnDefinition.should_receive(:new).with(@column_attributes)
    Schema::ColumnGroupBuilder.new.varchar :username

    ColumnDefinition.should_receive(:new).with(:type => :money, :name => :fee)
    Schema::ColumnGroupBuilder.new.money :fee
  end

  it "should return a list of defined columns" do
    stubbed_definition = stub()
    ColumnDefinition.should_receive(:new).with(@column_attributes).and_return(stubbed_definition)
    dd = Schema::ColumnGroupBuilder.new
    dd.varchar :username
    dd.column_definitions.should include(stubbed_definition)
  end

  it "should accept a column definition instead of a hash" do
    definition = ColumnDefinition.new(@column_attributes)
    dd = Schema::ColumnGroupBuilder.new
    dd.column definition
    dd.column_definitions.should include(definition)
  end

  it "should accept a block on creation" do
    ColumnDefinition.should_receive(:new).with(@column_attributes)
    Schema::ColumnGroupBuilder.new { varchar :username }
  end
end
