require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::AlterDbTableCommand do
  before :each do
    TEST_DB.drop_table(:test_table) if TEST_DB.table_exists?(:test_table)
    TEST_DB.create_table(:test_table) { integer :id }
  end

  it "should make no changes if the schema is the same" do
    columns = [stub(:name => :id, :type => :integer)]

    lambda do
      Schema::AlterDbTableCommand.new(TEST_DB, :test_table, columns).execute 
    end.should_not raise_error(Sequel::DatabaseError)
  end

  it "should add any new columns to the table" do
    columns = [stub(:name => :id, :type => :integer),
               stub(:name => :username, :type => :varchar)]
    Schema::AlterDbTableCommand.new(TEST_DB, :test_table, columns).execute

    TEST_DB.schema(:test_table).size.should == 2
    TEST_DB.schema(:test_table).last.first.should == :username
  end
end
