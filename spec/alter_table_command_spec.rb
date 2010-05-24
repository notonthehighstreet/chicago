require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::AlterTableCommand do
  before :each do
    TEST_DB.drop_table(:test_table) if TEST_DB.table_exists?(:test_table)
    TEST_DB.create_table(:test_table) { integer :id, :null => false }
  end

  it "should make no changes if the schema is the same" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer)]

    lambda do
      Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table 
    end.should_not raise_error(Sequel::DatabaseError)
  end

  it "should add any new columns to the table" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer),
               ColumnDefinition.new(:name => :username, :type => :varchar)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table

    TEST_DB.schema(:test_table).size.should == 2
    TEST_DB.schema(:test_table).last.first.should == :username
  end

  it "should change an existing column rather than adding a new column" do
    columns = [ColumnDefinition.new(:name => :id, :type => :float)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table
    TEST_DB.schema(:test_table).size.should == 1
  end

  it "should change a column's type if the definition has changed" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer, :min => -1000, :max => 300)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table

    TEST_DB.schema(:test_table, :reload => true).first.last[:db_type].should == "smallint(6)"
  end

  it "should change a column's type to unsigned" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer, :min => 0, :max => 300)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table
    
    TEST_DB.schema(:test_table, :reload => true).first.last[:db_type].should == "smallint(5) unsigned"
  end

  it "should change a column's null constraint" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer, :null => false)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table
    
    TEST_DB.schema(:test_table, :reload => true).first.last[:allow_null].should be_false
  end

  it "should change a column's default" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer, :default => 23)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table
    
    TEST_DB.schema(:test_table, :reload => true).first.last[:default].to_i.should == 23
  end

  it "should change both the type and the null constraint" do
    columns = [ColumnDefinition.new(:name => :id, :type => :integer, :min => -1000, :max => 300, :null => true)]
    Schema::AlterTableCommand.new(TEST_DB, :test_table, columns).create_or_modify_table

    attrs = TEST_DB.schema(:test_table, :reload => true).first.last
    attrs[:db_type].should == "smallint(6)"
    attrs[:allow_null].should be_true
  end
end
