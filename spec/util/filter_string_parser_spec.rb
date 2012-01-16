require "spec_helper"

describe Chicago::FilterStringParser do
  before :each do
    @dataset = TEST_DB[:test]
  end
  
  it "should parse 'dimension.field:value'" do
    @dataset = FilterStringParser.new("date.year:2010").apply_to(@dataset)
    @dataset.opts[:where].should == Sequel::SQL::BooleanExpression.from_value_pairs(:year.qualify(:dimension_date) => "2010")
  end

  it "should parse 'dimension:value'" do
    @dataset = FilterStringParser.new("date:1").apply_to(@dataset)
    @dataset.opts[:where].should == Sequel::SQL::BooleanExpression.from_value_pairs(:original_id.qualify(:dimension_date) => "1")
  end

  it "should parse 'dimension.field:value1,value2'" do
    @dataset = FilterStringParser.new("date.year:2010,2009").apply_to(@dataset)
    @dataset.opts[:where].should == Sequel::SQL::BooleanExpression.from_value_pairs(:year.qualify(:dimension_date) => ["2010", "2009"])
  end

  it "should raise an exception if there is no value" do
    lambda { FilterStringParser.new("date.year:") }.should raise_error("Missing Value")
  end

  it "should raise an exception if there is no field" do
    lambda { FilterStringParser.new(":") }.should raise_error("Missing valid filter dimension/field")
  end

  it "should parse 'dimension.field:value;dimension.field:value'" do
    dataset = mock(:dataset)
    dataset.should_receive(:filter).with(:year.qualify(:dimension_date) => "2010").and_return(dataset)
    dataset.should_receive(:filter).with(:month.qualify(:dimension_date) => "May").and_return(dataset)

    FilterStringParser.new("date.year:2010;date.month:May").apply_to(dataset)
  end

  it "should return a set of dimensions that have been used in filtering" do
    parser = FilterStringParser.new("date.year:2010;date.month:May")
    parser.dimensions.should == Set.new([:date])
  end
end
