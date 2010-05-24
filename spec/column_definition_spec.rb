require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::ColumnDefinition do
  it "should have a name" do
    ColumnDefinition.new(:name => :username, :type => :string).name.should == :username
    lambda { ColumnDefinition.new(:type => :string) }.should raise_error(DefinitionError)
  end

  it "should have a type" do
    ColumnDefinition.new(:name => :username, :type => :string).column_type.should == :string
    lambda { ColumnDefinition.new(:name => :username) }.should raise_error(DefinitionError)
  end

  it "should be equal to another column definition with the same attributes" do
    d1 = ColumnDefinition.new(:name => :username, :type => :string )
    d2 = ColumnDefinition.new(:name => :username, :type => :string )
    d1.should == d2
    d1.hash.should == d2.hash
  end

  it "should not be equal to another column definition with the different attributes" do
    d1 = ColumnDefinition.new(:name => :username, :type => :string )
    d2 = ColumnDefinition.new(:name => :username, :type => :integer )
    d1.should_not == d2
  end

  it "should have a #min method" do
    ColumnDefinition.new(:name => :username, :type => :string, :min => 0 ).min.should == 0
  end

  it "should have a #max method" do
    ColumnDefinition.new(:name => :username, :type => :string, :max => 10 ).max.should == 10
  end

  it "should set min and max from an enumerable object's min and max" do
    column = ColumnDefinition.new(:name => :username, :type => :string, :range => 1..5 )
    column.min.should == 1
    column.max.should == 5
  end

  it "should allow null values by default" do
    ColumnDefinition.new(:name => :username, :type => :string).null?().should be_true
  end

  it "should allow you to enforce non-null values" do
    ColumnDefinition.new(:name => :username, :type => :string, :null => false).null?().should be_false
  end

  it "can define a set of valid elements" do
    ColumnDefinition.new(:name => :username, :type => :string, :elements => ['A', 'B']).elements.should == ['A', 'B']
  end

  it "can have a default value" do
    ColumnDefinition.new(:name => :username, :type => :string, :default => 'A').default.should == 'A'
  end
end
