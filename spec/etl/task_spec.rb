require 'spec_helper'
require 'timeout'

describe Chicago::ETL::TaskInvocation do
  before :all do
    TEST_DB.drop_table(*(TEST_DB.tables))
    ETL::TableBuilder.build(TEST_DB)
    ETL::TaskInvocation.db = TEST_DB
  end

  before :each do
    TEST_DB[:etl_task_invocations].truncate
    TEST_DB[:etl_batches].truncate
  end
  
  after :each do
    tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))
    FileUtils.rm_r(tmpdir) if File.exists?(tmpdir)
  end
  
  it "should be associated with an ETL Batch" do
    batch = create_batch
    batch.should_not be_nil
    t = ETL::TaskInvocation.create(:batch => batch)
    t.reload.batch.should == batch
  end

  it "should be unqiue by name across an ETL Batch and stage" do
    attrs = {:batch_id => 1, :stage => "Extract", :name => "foo"}
    ETL::TaskInvocation.create(attrs)
    lambda { ETL::TaskInvocation.create(attrs) }.should raise_error(Sequel::DatabaseError)
  end

  it "should be in the 'Created' state by default" do
    ETL::TaskInvocation.create.state.should == "Created"
  end

  it "should perform an action in a block, and set it's state to Error if an exception is raised" do
    task = ETL::TaskInvocation.create
    lambda { task.perform { raise "Boom" } }.should raise_error(RuntimeError, "Boom")
    task.state.should == "Error"
  end

  it "should perform an action in a block, and set it's state to Error if an timeout error is raised" do
    task = ETL::TaskInvocation.create
    lambda { task.perform { raise Timeout::Error.new("Timeout error") } }.should raise_error(Timeout::Error)
    task.state.should == "Error"
  end

  it "should be in the 'Started' state while perform is called" do
    task = ETL::TaskInvocation.create
    task.perform { task.state.should == "Started" }
  end

  it "should be in the 'Finished' state after #perform has finished" do
    task = ETL::TaskInvocation.create
    task.perform {}
    task.state.should == "Finished"
    task.finished_at.should be_kind_of(Time)
  end

  it "should raise a RuntimeError if perform is attempted after the task has finished" do
    task = ETL::TaskInvocation.create
    task.perform {}
    lambda { task.perform {} }.should raise_error(RuntimeError)
  end

  it "should increment the number of attempts each time the task is performed" do
    task = ETL::TaskInvocation.create
    task.perform { raise "Boom" } rescue nil
    task.attempts.should == 1
    task.perform { raise "Boom" } rescue nil
    task.attempts.should == 2
  end

  it "should set the associated batch into an error state" do
    batch = create_batch
    task = ETL::TaskInvocation.create(:batch => batch)
    task.perform { raise "Boom" } rescue nil
    task.batch.should be_in_error
  end

  def create_batch
    Chicago.project_root = File.expand_path(File.join(File.dirname(__FILE__), ".."))
    ETL::Batch.create
  end
end
