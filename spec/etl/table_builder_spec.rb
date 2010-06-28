require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::ETL::TableBuilder do
  before :each do
    TEST_DB.drop_table(*(TEST_DB.tables))
  end

  it "should create an etl_batches table" do
    ETL::TableBuilder.build(TEST_DB)
    TEST_DB.tables.should include(:etl_batches)
  end

  it "should create an etl_task_invocations table" do
    ETL::TableBuilder.build(TEST_DB)
    TEST_DB.tables.should include(:etl_task_invocations)
  end

  it "should do nothing and not raise an error if run more times than necessary" do
    ETL::TableBuilder.build(TEST_DB)
    lambda { ETL::TableBuilder.build(TEST_DB) }.should_not raise_error(Sequel::DatabaseError)
  end
end
