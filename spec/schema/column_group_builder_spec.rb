require "spec_helper"

describe Chicago::Schema::ColumnGroupBuilder do
  before :each do
    @dimension = stub(:dimension)
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should create a column definition" do
    Schema::Column.should_receive(:new).with(@dimension, :username, :string, {})
    Schema::ColumnGroupBuilder.new(@dimension).column :type => :string, :name => :username
  end

  it "should support arbitrary column definitions as methods" do
    Schema::Column.should_receive(:new).with(@dimension, :username, :string, {})
    Schema::ColumnGroupBuilder.new(@dimension).string :username

    Schema::Column.should_receive(:new).with(@dimension, :fee, :money, {})
    Schema::ColumnGroupBuilder.new(@dimension).money :fee
  end

  it "should return a list of defined columns" do
    dd = Schema::ColumnGroupBuilder.new(@dimension)
    dd.string :username
    dd.column_definitions.should == [Schema::Column.new(@dimension, :username, :string)]
  end

  it "should accept a column definition instead of a hash" do
    definition = Schema::Column.new(@dimension, :username, :string)
    dd = Schema::ColumnGroupBuilder.new(@dimension)
    dd.column definition
    dd.column_definitions.should include(definition)
  end

  it "should accept a block on creation" do
    builder = Schema::ColumnGroupBuilder.new(@dimension) { string :username }
    builder.column_definitions.should == [Schema::Column.new(@dimension, :username, :string)]
  end

  it "should take a hash of defaults options" do
    builder = Schema::ColumnGroupBuilder.new(@dimension, :null => true) { string :username }
    builder.column_definitions.should == [Schema::Column.new(@dimension, :username, :string, :null => true)]
  end
end
