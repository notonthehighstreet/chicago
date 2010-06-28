require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::Column do
  it "should have a name" do
    Schema::Column.new(:username, :string).name.should == :username
  end

  it "should have a column type" do
    Schema::Column.new(:username, :string).column_type.should == :string
  end

  it "should be equal to another column definition with the same attributes" do
    Schema::Column.new(:username, :string).should == Schema::Column.new(:username, :string)
  end

  it "should not be equal to another column definition with the different attributes" do
    Schema::Column.new(:username, :string).should_not == Schema::Column.new(:username, :integer)
  end

  it "should have a #min method" do
    Schema::Column.new(:username, :string, :min => 0 ).min.should == 0
  end

  it "should have a min of 0 by default for money columns" do
    Schema::Column.new(:username, :money).min.should == 0
  end

  it "should have a #max method" do
    Schema::Column.new(:username, :string, :max => 10 ).max.should == 10
  end

  it "should set min and max from an enumerable object's min and max" do
    column = Schema::Column.new(:username, :string, :range => 1..5 )
    column.min.should == 1
    column.max.should == 5
  end

  it "should forbid null values by default" do
    Schema::Column.new(:username, :string).should_not be_null
  end

  it "should allow you to accept non-null values" do
    Schema::Column.new(:username, :string, :null => true).should be_null
  end

  it "should allow null values by default for date, datetime or timestamp columns" do
    Schema::Column.new(:username, :timestamp).should be_null
    Schema::Column.new(:username, :date).should be_null
    Schema::Column.new(:username, :datetime).should be_null
  end

  it "can define a set of valid elements" do
    Schema::Column.new(:username, :string, :elements => ['A', 'B']).elements.should == ['A', 'B']
  end

  it "can have a default value" do
    Schema::Column.new(:username, :string, :default => 'A').default.should == 'A'
  end

  it "should have a descriptive? method, false by default" do
    Schema::Column.new(:username, :string).should_not be_descriptive
  end

  it "should be definable as descriptive" do
    Schema::Column.new(:username, :string, :descriptive => true).should be_descriptive
  end

  it "should be numeric if an integer" do
    Schema::Column.new(:username, :integer).should be_numeric
  end

  it "should be numeric if a money" do
    Schema::Column.new(:username, :money).should be_numeric
  end

  it "should be numeric if a float" do
    Schema::Column.new(:username, :float).should be_numeric
  end

  it "should be numeric if a decimal" do
    Schema::Column.new(:username, :decimal).should be_numeric
  end

  it "should be numeric if a percentage" do
    Schema::Column.new(:username, :percent).should be_numeric
  end

  it "should not be numeric if a string" do
    Schema::Column.new(:username, :string).should_not be_numeric
  end
end

describe "A Hash returned by Chicago::Column#db_schema" do
  before :each do
    @tc = Chicago::Schema::TypeConverters::DbTypeConverter.for_db(stub(:database_type => :generic))
  end

  it "should have a :name entry" do
    Schema::Column.new(:username, :string, :max => 8).db_schema(@tc)[:name].should == :username
  end

  it "should have a :column_type entry" do
    Schema::Column.new(:username, :string, :max => 8).db_schema(@tc)[:column_type].should == :varchar
  end

  it "should not have a :default entry by default" do
    Schema::Column.new(:username, :string).db_schema(@tc).keys.should_not include(:default)
  end

  it "should have a :default entry if specified" do
    Schema::Column.new(:username, :string, :default => 'A').db_schema(@tc)[:default].should == 'A'
  end

  it "should have an :unsigned entry if relevant" do
    Schema::Column.new(:id, :integer, :min => 0).db_schema(@tc)[:unsigned].should be_true
  end

  it "should have an :entries entry if relevant" do
    Schema::Column.new(:username, :string, :elements => ['A']).db_schema(@tc)[:elements].should == ['A']
  end

  it "should not have an :entries entry if relevant" do
    Schema::Column.new(:username, :string).db_schema(@tc).keys.should_not include(:elements)
  end

  it "should have a :size entry if max is present and type is string" do
    Schema::Column.new(:username, :string, :max => 8).db_schema(@tc)[:size].should == 8
  end

  it "should have a default :size of [12,2] for money types" do
    Schema::Column.new(:some_value, :money).db_schema(@tc)[:size].should == [12,2]
  end

  it "should be unsigned by default if a percentage" do
    Schema::Column.new(:some_value, :percent).db_schema(@tc)[:unsigned].should be_true
  end

  it "should have a default :size of [6,3] for percent types" do
    Schema::Column.new(:rate, :percent).db_schema(@tc)[:size].should == [6,3]
  end

  it "should have a :size that is set explictly" do
    Schema::Column.new(:username, :money, :size => 'huge').db_schema(@tc)[:size].should == 'huge'
  end

  it "should explicitly set the default to nil for timestamp columns" do
    Schema::Column.new(:username, :timestamp).db_schema(@tc).has_key?(:default).should be_true
    Schema::Column.new(:username, :timestamp).db_schema(@tc)[:default].should be_nil
  end
end
