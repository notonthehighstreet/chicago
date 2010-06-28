require File.dirname(__FILE__) + "/../spec_helper"
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

  it "should be unqiue by name across an ETL Batch" do
    attrs = {:batch_id => 1, :name => "foo"}
    ETL::TaskInvocation.create(attrs)
    lambda { ETL::TaskInvocation.create(attrs) }.should raise_error(Sequel::DatabaseError)
  end

  it "should be in the 'Created' state by default" do
    ETL::TaskInvocation.create.state.should == "Created"
  end

  it "should perform an action in a block, and set it's state to Error if an exception is raised" do
    task = ETL::TaskInvocation.create
    lambda { task.perform { raise "Boom" } }.should raise_error
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
    lambda { task.perform { raise "Boom" } }.should raise_error
    task.attempts.should == 1
    lambda { task.perform { raise "Boom" } }.should raise_error
    task.attempts.should == 2
  end
end
