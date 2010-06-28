require File.dirname(__FILE__) + "/../spec_helper"
require 'fileutils'

describe Chicago::ETL::Batch do
  before :each do
    TEST_DB.drop_table(*(TEST_DB.tables))
    ETL::TableBuilder.build(TEST_DB)
    ETL::Batch.db = TEST_DB
    Chicago.project_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))
    FileUtils.rm_r(tmpdir) if File.exists?(tmpdir)
  end

  it "should return a new batch when start is called and there are no outstanding batches in error" do
    ETL::Batch.start.should be_kind_of(ETL::Batch)
  end

  it "should set the start timestamp of the batch to now when created" do
    ETL::Batch.start.started_at.to_i.should == Time.now.to_i
  end

  it "should have a state of 'Started' when started" do
    ETL::Batch.start.state.should == "Started"
  end

  it "should create a directory tmp/batches/1 under the project root when created" do
    ETL::Batch.start
    File.should be_directory(Chicago.project_root + "/tmp/batches/1")
  end

  it "should return the batch directory path from #dir" do
    ETL::Batch.start.dir.should == Chicago.project_root + "/tmp/batches/1"
  end

  it "should set the finished_at timestamp when #finish is called" do
    batch = ETL::Batch.start
    batch.finish
    batch.finished_at.should_not be_nil
    batch.state.should == "Finished"
  end

  it "should return true from #error? if in the error state" do
    batch = ETL::Batch.start
    batch.error
    batch.should be_in_error
  end

  it "should not return a new batch if the last batch was not finished" do
    batch = ETL::Batch.start
    ETL::Batch.start.should == batch
  end

  it "should not return a new batch if the last batch ended in error" do
    batch = ETL::Batch.start
    batch.error
    ETL::Batch.start.should == batch
  end
end
