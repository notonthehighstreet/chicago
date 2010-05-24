require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Dimension do
  before :each do
    @column_attributes = {:type => :varchar, :name => :username}
  end

  it "should be constructed with a dimension name" do
    Dimension.define(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    Dimension.define('user').name.should == :user
  end

  it "should have a table name" do
    Dimension.define(:user).table_name.should == :user_dimension
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    dd = Dimension.define(:user) do
      columns { varchar :username }
    end

    dd.column_definitions.should == [column]
  end

  it "should specify a main identifier column" do
    Dimension.define(:user) { identified_by :username }.main_identifier.should == :username
  end

  it "should allow additional identifying columns" do
    dimension = Dimension.define(:user) { identified_by :username, :and => [:email] }

    dimension.main_identifier.should == :username
    dimension.identifiers.should == [:username, :email]
  end
end
