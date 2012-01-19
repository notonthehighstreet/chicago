require 'spec_helper'

describe Chicago::Column do
  subject { described_class.new(:user_name, :string) }

  it_behaves_like "a column"
  
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

  it "is indexed by default" do
    described_class.new(:rate, :integer).should be_indexed
  end

  it "should not be indexed if descriptive" do
    described_class.new(:username, :string, :descriptive => true).should_not be_indexed
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

  it "is visitable" do
    visitor = mock(:visitor)
    column = described_class.new(:foo, :integer)
    visitor.should_receive(:visit_column).with(column)
    column.visit(visitor)
  end
end

describe "Chicago::Column#hash" do
  it "should have a :name entry" do
    Chicago::Column.new(:username, :string, :max => 8).to_hash[:name].should == :username
  end

  it "should have a :column_type entry" do
    Chicago::Column.new(:username, :string, :max => 8).to_hash[:column_type].should == :string
  end

  it "should not have a :default entry by default" do
    Chicago::Column.new(:username, :string).to_hash.keys.should_not include(:default)
  end

  it "should have a :default entry if specified" do
    Chicago::Column.new(:username, :string, :default => 'A').to_hash[:default].should == 'A'
  end

  it "should have an :unsigned entry if relevant" do
    Chicago::Column.new(:id, :integer, :min => 0).to_hash[:unsigned].should be_true
  end

  it "should have an :entries entry if relevant" do
    Chicago::Column.new(:username, :string, :elements => ['A']).to_hash[:elements].should == ['A']
  end

  it "should not have an :entries entry if relevant" do
    Chicago::Column.new(:username, :string).to_hash.keys.should_not include(:elements)
  end

  it "should have a :size entry if max is present and type is string" do
    Chicago::Column.new(:username, :string, :max => 8).to_hash[:size].should == 8
  end

  it "should have a default :size of [12,2] for money types" do
    Chicago::Column.new(:some_value, :money).to_hash[:size].should == [12,2]
  end

  it "should be unsigned by default if a percentage" do
    Chicago::Column.new(:some_value, :percent).to_hash[:unsigned].should be_true
  end

  it "should have a default :size of [6,3] for percent types" do
    Chicago::Column.new(:rate, :percent).to_hash[:size].should == [6,3]
  end

  it "should have a :size that is set explictly" do
    Chicago::Column.new(:username, :money, :size => 'huge').to_hash[:size].should == 'huge'
  end

  it "should explicitly set the default to nil for timestamp columns" do
    Chicago::Column.new(:username, :timestamp).to_hash.has_key?(:default).should be_true
    Chicago::Column.new(:username, :timestamp).to_hash[:default].should be_nil
  end
end
