require 'spec_helper'

describe Chicago::Schema::Fact do
  it_behaves_like "a named schema element"

  it "has a table name" do
    described_class.new("foo").table_name.should == :facts_foo
  end
  
  it "has no dimensions by default" do
    described_class.new("foo").dimensions.should be_empty
  end

  it "has no degenerate dimensions by default" do
    described_class.new("foo").degenerate_dimensions.should be_empty
  end

  it "has no measures by default" do
    described_class.new("foo").degenerate_dimensions.should be_empty
  end

  it "can have dimensions" do
    dimension = stub(:dimension)
    described_class.new("foo", :dimensions => [dimension]).
      dimensions.should == [dimension]
  end

  it "has degenerate dimensions" do
    column = stub(:column)
    described_class.new("foo", :degenerate_dimensions => [column]).
      degenerate_dimensions.should == [column]
  end

  it "has measures" do
    column = stub(:column)
    described_class.new("foo", :measures => [column]).
      measures.should == [column]
  end

  it "has columns defined as dimensions, degenerate dimensions & measures" do

    dimension = stub(:dimension)
    column = stub(:column)
    column_2 = stub(:column_2)
    fact = described_class.new("foo",
                             :dimensions => [dimension],
                             :degenerate_dimensions => [column],
                             :measures => [column_2])
    fact.columns.should == [dimension, column, column_2]
  end

  it "can qualify a column" do
    described_class.new(:foo).qualify(stub(:column, :name => :bar)).
      should == :bar.qualify(:facts_foo)
  end

  it "provides a hash-like accessor syntax for columns" do
    measure = stub(:column, :name => :bar)
    fact = described_class.new(:foo, :measures => [measure])
    fact[:bar].should == measure
  end

  it "is factless if it has no measures" do
    described_class.new(:foo, :measures => [stub()]).should_not be_factless
    described_class.new(:foo).should be_factless    
  end

  it "can define a natural key" do
    described_class.new(:f, :natural_key => [:foo, :bar]).
      natural_key.should == [:foo, :bar]
  end

  it "is visitable" do
    visitor = mock(:visitor)
    fact = described_class.new(:foo)
    visitor.should_receive(:visit_fact).with(fact)
    fact.visit(visitor)
  end
end
