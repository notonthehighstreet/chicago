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

  it "should set the start timestamp of the batch to now when created" do
    ETL::Batch.create.started_at.to_i.should == Time.now.to_i
  end

  it "should create a directory tmp/batches/1 under the project root when created" do
    ETL::Batch.create
    File.should be_directory(Chicago.project_root + "/tmp/batches/1")
  end

  it "should return the batch directory path from #dir" do
    ETL::Batch.create.dir.should == Chicago.project_root + "/tmp/batches/1"
  end
end
