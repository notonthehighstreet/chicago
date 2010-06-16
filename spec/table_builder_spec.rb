require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::TableBuilder do
  before :each do
    @mock_db = mock(:db)
    @builder = TableBuilder.new(@mock_db)
  end

  it "should build a migration file called initial migration" do
    dimension = mock(:dimension)
    Dimension.should_receive(:definitions).and_return([dimension])
    dimension.should_receive(:db_schema).and_return(:table => :definitions)
    Fact.should_receive(:definitions).and_return([])

    @builder.build_migration_file

  end
end
