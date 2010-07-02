require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::Dimension do
  it "should be constructed with a dimension name" do
    Schema::Dimension.define(:user).name.should == :user
  end

  it "should return a symbol from #name" do
    Schema::Dimension.define('user').name.should == :user
  end

  it "should have a table name" do
    Schema::Dimension.define(:user).table_name.should == :dimension_user
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

describe "Chicago::Dimension#db_schema" do
  before :each do 
    @dimension = Schema::Dimension.define(:user)
    @tc = Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :generic))
  end

  it "should define a user_dimension table" do
    @dimension.db_schema(@tc).keys.should include(:dimension_user)
  end

  it "should have an unsigned integer :id column" do
    expected = {:name => :id, :column_type => :integer, :unsigned => true}
    @dimension.db_schema(@tc)[:dimension_user][:columns].should include(expected)
  end

  it "should define :id as the primary key" do
    @dimension.db_schema(@tc)[:dimension_user][:primary_key].should == [:id]
  end

  it "should include a hash of table options" do
    @dimension.db_schema(@tc)[:dimension_user][:table_options].should == {}
  end

  it "should have a table type of MyISAM for mysql" do
    @tc = Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :mysql))
    @dimension.db_schema(@tc)[:dimension_user][:table_options].should == {:engine => "myisam"}
  end

  it "should include the sequel schema for the defined columns" do
    @dimension.columns do
      string :username, :max => 10
    end

    expected = {:name => :username, :column_type => :varchar, :size => 10, :null => false}
    @dimension.db_schema(@tc)[:dimension_user][:columns].should include(expected)
  end

  it "should output indexes for every column that isn't descriptive" do
    @dimension.columns do
      string :foo, :descriptive => true
      string :bar
      string :baz
    end

    expected = {:bar_idx => {:columns => :bar}, :baz_idx => {:columns => :baz}}
    @dimension.db_schema(@tc)[:dimension_user][:indexes].should == expected
  end

  # This just supports internal convention at the moment
  it "should create a key mapping table if an original_id column is present" do
    @dimension.columns do
      integer :original_id, :min => 0
      string :username, :max => 10
    end

    key_table = @dimension.db_schema(@tc)[:keys_dimension_user]
    key_table.should_not be_nil
    key_table[:primary_key].should == [:original_id, :dimension_id]

    expected = [{:name => :original_id, :column_type => :integer, :null => false, :unsigned => true},
                {:name => :dimension_id, :column_type => :integer, :null => false, :unsigned => true}]
    key_table[:columns].should == expected
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
