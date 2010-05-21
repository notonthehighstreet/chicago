require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::ColumnDefinition do
  it "should have a name" do
    ColumnDefinition.new(:name => :username, :type => :varchar).name.should == :username
    lambda { ColumnDefinition.new(:type => :varchar) }.should raise_error(DefinitionError)
  end

  it "should have a type" do
    ColumnDefinition.new(:name => :username, :type => :varchar).column_type.should == :varchar
    lambda { ColumnDefinition.new(:name => :username) }.should raise_error(DefinitionError)
  end

  it "should be equal to another column definition with the same attributes" do
    d1 = ColumnDefinition.new(:name => :username, :type => :varchar )
    d2 = ColumnDefinition.new(:name => :username, :type => :varchar )
    d1.should == d2
    d1.hash.should == d2.hash
  end

  it "should not be equal to another column definition with the different attributes" do
    d1 = ColumnDefinition.new(:name => :username, :type => :varchar )
    d2 = ColumnDefinition.new(:name => :username, :type => :integer )
    d1.should_not == d2
  end

  it "should have a #min method" do
    ColumnDefinition.new(:name => :username, :type => :varchar, :min => 0 ).min.should == 0
  end

  it "should have a #max method" do
    ColumnDefinition.new(:name => :username, :type => :varchar, :max => 10 ).max.should == 10
  end
end
