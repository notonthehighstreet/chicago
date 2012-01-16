require 'spec_helper'

describe Chicago::Column do
  it "has a human-friendly label" do
    described_class.new(:user_name, :string).label.should == "User Name"
  end

  it "should have a name" do
    described_class.new(:username, :string).name.should == :username
  end

  it "should have a column type" do
    described_class.new(:username, :string).column_type.should == :string
  end

  it "should be equal to another column definition with the same attributes" do
    described_class.new(:username, :string).should == described_class.new(:username, :string)
  end

  it "should not be equal to another column definition with the different attributes" do
    described_class.new(:username, :string).should_not == described_class.new(:username, :integer)
  end

  it "should have a #min method" do
    described_class.new(:username, :string, :min => 0).min.should == 0
  end

  it "should have a min of 0 by default for money columns" do
    described_class.new(:username, :money).min.should == 0
  end

  it "should have a #max method" do
    described_class.new(:username, :string, :max => 10).max.should == 10
  end

  it "should set min and max from an enumerable object's min and max" do
    column = described_class.new(:username, :string, :range => 1..5)
    column.min.should == 1
    column.max.should == 5
  end

  it "should forbid null values by default" do
    described_class.new(:username, :string).should_not be_null
  end

  it "should allow you to accept non-null values" do
    described_class.new(:username, :string, :null => true).should be_null
  end

  it "should allow null values by default for date, datetime or timestamp columns" do
    described_class.new(:username, :timestamp).should be_null
    described_class.new(:username, :date).should be_null
    described_class.new(:username, :datetime).should be_null
  end

  it "can define a set of valid elements" do
    described_class.new(:username, :string, :elements => ['A', 'B']).elements.should == ['A', 'B']
  end

  it "can have a default value" do
    described_class.new(:username, :string, :default => 'A').default.should == 'A'
  end

  it "should have a descriptive? method, false by default" do
    described_class.new(:username, :string).should_not be_descriptive
  end

  it "should be definable as descriptive" do
    described_class.new(:username, :string, :descriptive => true).should be_descriptive
  end

  it "should be numeric if an integer" do
    described_class.new(:username, :integer).should be_numeric
  end

  it "should be numeric if a money" do
    described_class.new(:username, :money).should be_numeric
  end

  it "should be numeric if a float" do
    described_class.new(:username, :float).should be_numeric
  end

  it "should be numeric if a decimal" do
    described_class.new(:username, :decimal).should be_numeric
  end

  it "should be numeric if a percentage" do
    described_class.new(:username, :percent).should be_numeric
  end

  it "should not be numeric if a string" do
    described_class.new(:username, :string).should_not be_numeric
  end

  it "can be countable" do
    col = described_class.new(:username, :string, :countable => true)
    col.should be_countable
    col.countable_label.should == col.label
  end

  it "can have a specific label when counted" do
    col = described_class.new(:username, :string, :countable => "No. of users")
    col.should be_countable
    col.countable_label.should == "No. of users"
  end

  it "can be internal, i.e. for internal use only, and not to be displayed in an interface" do
    described_class.new(:random_ref, :string, :internal => true).
      should be_internal
  end
end
