require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::TableBuilder do
  before :each do
    @mock_db = mock(:db)
    @builder = Schema::TableBuilder.new(@mock_db)
  end
  
  it "should create a table if it doesn't exist" do
    @mock_db.should_receive(:table_exists?).with(:test_table).and_return(false)
    Schema::CreateTableCommand.
      should_receive(:new).with(@mock_db, :test_table, []).and_return(command)

    @builder.build(:test_table, [])
  end

  it "should alter a table if it already exists" do
    @mock_db.should_receive(:table_exists?).with(:test_table).and_return(true)
    Schema::AlterTableCommand.
      should_receive(:new).with(@mock_db, :test_table, []).and_return(command)

    @builder.build(:test_table, [])
  end

  def command
    c = mock(:command)
    c.should_receive(:create_or_modify_table)
    c
  end
end
