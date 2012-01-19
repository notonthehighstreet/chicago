require "spec_helper"

describe Chicago::Schema::Dimension do
  it "should be constructed with a dimension name" do
    Schema::Dimension.define(:user).name.should == :user
  end

  it "should have a human-friendly label" do
    Schema::Dimension.define(:user).label.should == "User"
  end
  
  it "should return a symbol from #name" do
    Schema::Dimension.define('user').name.should == :user
  end

  it "should return the named dimension from []" do
    dimension = Schema::Dimension.define(:user)
    Schema::Dimension[:user].should == dimension
  end

  it "should have a table name" do
    Schema::Dimension.define(:user).table_name.should == :dimension_user
  end

  it "should be identifiable if it has an original key" do
    Schema::Dimension.define(:user) do
      columns do
        integer :original_id
      end
    end.should be_identifiable
  end
  
  it "should know every defined dimension" do
    Schema::Dimension.clear_definitions
    Schema::Dimension.define(:user)
    Schema::Dimension.define(:product)
    Schema::Dimension.definitions.size.should == 2
    Schema::Dimension.definitions.map {|d| d.name }.should include(:user)
    Schema::Dimension.definitions.map {|d| d.name }.should include(:product)
  end

  it "should not include fact definitions in its definitions" do
    Schema::Dimension.clear_definitions
    Schema::Fact.define(:sales)
    Schema::Dimension.definitions.should be_empty
  end

  it "should be able to clear previously defined dimensions with #clear_definitions" do
    Schema::Dimension.define(:user)
    Schema::Dimension.clear_definitions
    Schema::Dimension.definitions.should be_empty
  end

  it "should define a group of columns" do
    column = stub(:column)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.should_receive(:new).and_return(mock_builder)
    mock_builder.should_receive(:column_definitions).and_return([column])

    dd = Schema::Dimension.define(:user) do
      columns { string :username }
    end

    dd.column_definitions.should == [column]
  end

  it "returns a column from #[]" do
    column = stub(:column, :name => :col_name)
    mock_builder = mock(:builder)
    Schema::ColumnGroupBuilder.stub(:new).and_return(mock_builder)
    mock_builder.stub(:column_definitions).and_return([column])

    dd = Schema::Dimension.define(:user) do
      columns { string :username }
    end

    dd[:col_name] == [column]
  end

  it "should specify a main identifier column" do
    Schema::Dimension.define(:user) { identified_by :username }.main_identifier.should == :username
  end

  it "should allow additional identifying columns" do
    dimension = Schema::Dimension.define(:user) { identified_by :username, :and => [:email] }

    dimension.main_identifier.should == :username
    dimension.identifiers.should == [:username, :email]
  end

  it "should define null records" do
    attributes = {:id => 1, :name => "Unknown User", :full_name => "Unknown User"}

    mock_db = mock(:db)
    mock_db.should_receive(:[]).with(:dimension_user).and_return(mock_db)
    mock_db.should_receive(:insert_replace).and_return(mock_db)
    mock_db.should_receive(:insert_multiple).with([attributes])

    dimension = Schema::Dimension.define(:user)
    dimension.null_record attributes
    dimension.create_null_records(mock_db)
  end

  it "should raise an error if a null record is defined without an id" do
    lambda { Schema::Dimension.define(:user).null_record({}) }.should raise_error(RuntimeError)
  end
end

describe "Conforming dimensions" do
  it "should be able to conform to another dimension" do
    Schema::Dimension.define(:date)
    lambda { Schema::Dimension.define(:month, :conforms_to => :date) }.should_not raise_error
  end

  it "should raise an error if you attempt to conform to a non-existent dimension" do
    Schema::Dimension.clear_definitions
    lambda { Schema::Dimension.define(:month, :conforms_to => :date) }.should raise_error
  end

  it "should copy column definitions from its parent dimension" do
    date_dimension = Schema::Dimension.define(:date) do
      columns do
        date   :date
        string :month
      end
    end
    definition = date_dimension.column_definitions.find {|d| d.name == :month }
    Schema::Dimension.define(:month, :conforms_to => :date) { columns :month }.
      column_definitions.first.should == definition
  end

  it "should raise an error if any extra columns are included (it doesn't conform)" do
    Schema::Dimension.define(:date) { columns { string :month } }
    lambda do 
      Schema::Dimension.define(:month, :conforms_to => :date) { columns :month, :year }
    end.should raise_error
  end
end
