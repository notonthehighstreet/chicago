require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::ETL::Batch do
  before :each do
    TEST_DB.drop_table(*(TEST_DB.tables))
    ETL::TableBuilder.build(TEST_DB)
    ETL::Batch.db = TEST_DB
    Chicago.project_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))
    FileUtils.rm_r(tmpdir) if File.exists?(tmpdir)
  end

  it "should return a new batch when instance is called and there are no outstanding batches in error" do
    ETL::Batch.instance.should be_new
  end

  it "should set the start timestamp of the batch to now when created" do
    ETL::Batch.instance.start.started_at.to_i.should == Time.now.to_i
  end

  it "should have a state of 'Started' when started" do
    ETL::Batch.instance.start.state.should == "Started"
  end

  it "should create a directory tmp/batches/1 under the project root when created" do
    ETL::Batch.instance.start
    File.should be_directory(Chicago.project_root + "/tmp/batches/1")
  end

  it "should return the batch directory path from #dir" do
    ETL::Batch.instance.start.dir.should == Chicago.project_root + "/tmp/batches/1"
  end

  it "should set the finished_at timestamp when #finish is called" do
    batch = ETL::Batch.instance.start
    batch.finish
    batch.finished_at.should_not be_nil
    batch.state.should == "Finished"
  end

  it "should return true from #error? if in the error state" do
    batch = ETL::Batch.instance.start
    batch.error
    batch.should be_in_error
  end

  it "should not return a new batch if the last batch was not finished" do
    batch = ETL::Batch.instance.start
    ETL::Batch.instance == batch
  end

  it "should not return a new batch if the last batch ended in error" do
    batch = ETL::Batch.instance.start
    batch.error
    ETL::Batch.instance.should == batch
  end

  it "should create a log in tmp/batches/1/log" do
    ETL::Batch.instance.start
    File.read(Chicago.project_root + "/tmp/batches/1/log").
      should include("Started ETL batch 1.")
  end

  it "should perform a task only once" do
    batch = ETL::Batch.instance.start
    i = 0
    2.times { batch.perform_task("Transform", "Test") { i += 1} }
    i.should == 1
    batch.task_invocations_dataset.filter(:stage => "Transform", :name => "Test").count.should == 1
  end

  it "should not complain when given a symbol as the stage name" do
    batch = ETL::Batch.instance.start
    lambda { batch.perform_task(:transform, "Test") {} }.should_not raise_error(Sequel::DatabaseError)
  end
end
