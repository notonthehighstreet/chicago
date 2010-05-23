require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Dimension do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should be constructed with a dimension name" do
    Dimension.new(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    Dimension.new('user').name.should == :user
  end

  it "should have a table name" do
    Dimension.new(:user).table_name.should == :user_dimension
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    dd = Dimension.new(:user)
    dd.columns { varchar :username }
    dd.column_definitions.should == [column]
  end
end
