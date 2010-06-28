require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::ColumnGroupBuilder do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should create a column definition" do
    Schema::Column.should_receive(:new).with(:username, :string, {})
    Schema::ColumnGroupBuilder.new.column :type => :string, :name => :username
  end

  it "should support arbitrary column definitions as methods" do
    Schema::Column.should_receive(:new).with(:username, :string, {})
    Schema::ColumnGroupBuilder.new.string :username

    Schema::Column.should_receive(:new).with(:fee, :money, {})
    Schema::ColumnGroupBuilder.new.money :fee
  end

  it "should return a list of defined columns" do
    dd = Schema::ColumnGroupBuilder.new
    dd.string :username
    dd.column_definitions.should == [Schema::Column.new(:username, :string)]
  end

  it "should accept a column definition instead of a hash" do
    definition = Schema::Column.new(:username, :string)
    dd = Schema::ColumnGroupBuilder.new
    dd.column definition
    dd.column_definitions.should include(definition)
  end

  it "should accept a block on creation" do
    builder = Schema::ColumnGroupBuilder.new { string :username }
    builder.column_definitions.should == [Schema::Column.new(:username, :string)]
  end

  it "should take a hash of defaults options" do
    builder = Schema::ColumnGroupBuilder.new(:null => true) { string :username }
    builder.column_definitions.should == [Schema::Column.new(:username, :string, :null => true)]
  end
end
