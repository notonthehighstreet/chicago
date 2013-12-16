require 'spec_helper'

describe Symbol do
  it "should have a distinct method" do
    :foo.distinct.should be_kind_of(Sequel::SQL::DistinctExpression)
  end
end

describe String do
  it "should have a distinct method" do
    "foo".distinct.should be_kind_of(Sequel::SQL::DistinctExpression)
  end
end

describe Sequel::SQL::Expression do
  it "should have a distinct method" do
    :if.sql_function(true, 1, 0).distinct.should be_kind_of(Sequel::SQL::DistinctExpression)
  end
end

describe Sequel::SQL::DistinctExpression do
  it "has a reader for the wrapped expression" do
    described_class.new(:foo).expression.should == :foo
  end

  it "is rendered as 'DISTINCT expression'" do
    described_class.new(:foo).sql_literal(TEST_DB[:foo]).should == "DISTINCT `foo`"
  end
end
