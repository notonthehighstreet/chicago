require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::CreateDbTableCommand do
  before :each do
    TEST_DB.drop_table(:test_table) if TEST_DB.table_exists?(:test_table)
    @klass = Schema::CreateDbTableCommand
  end

  after :each do
    TEST_DB.drop_table(:test_table) if TEST_DB.table_exists?(:test_table)
  end

  it "should create a table if it doesn't exist" do
    column_definition = ColumnDefinition.new(:name => :id, :type => :integer)
    @klass.new(TEST_DB, :test_table, [column_definition]).execute
    TEST_DB.table_exists?(:test_table).should be_true
  end

  it "should create a column in the newly created table" do
    column_definition = ColumnDefinition.new(:name => :id, :type => :integer)
    @klass.new(TEST_DB, :test_table, [column_definition]).execute
    column = TEST_DB.schema(:test_table).first
    column.first.should == :id
    column.last[:type].should == :integer
  end

  it "should raise a Sequel::DatabaseError if attempting to call it with the table already present" do
    TEST_DB.create_table(:test_table) { primary_key :id }
    lambda { @klass.new(TEST_DB, :test_table, []).execute }.should raise_error(Sequel::DatabaseError)
  end

  it "should create an unsigned integer if the min value >= 0" do
    column_definition = ColumnDefinition.new(:name => :id, :type => :integer, :min => 0)
    @klass.new(TEST_DB, :test_table, [column_definition]).execute
    
    TEST_DB.schema(:test_table).first.last[:db_type].should include("unsigned")
  end
end
