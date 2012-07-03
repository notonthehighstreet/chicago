require 'spec_helper'
require 'chicago/etl'

describe Chicago::ETL::BatchedDatasetFilter do
  it "should be filterable if the table has an etl_batch_id column" do
    db = stub(:db)
    db.stub(:schema).with(:foo).and_return([[:id, {}], [:etl_batch_id, {}]])
    db.stub(:schema).with(:bar).and_return([[:id, {}]])

    described_class.new(db).filterable?(:foo).should be_true
    described_class.new(db).filterable?(:bar).should be_false
  end

  it "creates an array of conditions" do
    db = stub(:db)
    db.stub(:schema).with(:foo).and_return([[:id, {}], [:etl_batch_id, {}]])
    db.stub(:schema).with(:bar).and_return([[:id, {}]])
    
    etl_batch = stub(:etl_batch, :id => 42)

    described_class.new(db).conditions([:foo, :bar], etl_batch).
      should == [{:etl_batch_id.qualify(:foo) => 42}]
  end
end
