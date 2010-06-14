require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::ColumnGroupBuilder do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should create a column definition" do
    ColumnDefinition.should_receive(:new).with(:username, :string, {})
    Schema::ColumnGroupBuilder.new.column :type => :string, :name => :username
  end

  it "should support arbitrary column definitions as methods" do
    ColumnDefinition.should_receive(:new).with(:username, :string, {})
    Schema::ColumnGroupBuilder.new.string :username

    ColumnDefinition.should_receive(:new).with(:fee, :money, {})
    Schema::ColumnGroupBuilder.new.money :fee
  end

  it "should return a list of defined columns" do
    dd = Schema::ColumnGroupBuilder.new
    dd.string :username
    dd.column_definitions.should == [ColumnDefinition.new(:username, :string)]
  end

  it "should accept a column definition instead of a hash" do
    definition = ColumnDefinition.new(:username, :string)
    dd = Schema::ColumnGroupBuilder.new
    dd.column definition
    dd.column_definitions.should include(definition)
  end

  it "should accept a block on creation" do
    builder = Schema::ColumnGroupBuilder.new { string :username }
    builder.column_definitions.should == [ColumnDefinition.new(:username, :string)]
  end
end
