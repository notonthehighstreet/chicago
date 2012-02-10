require 'spec_helper'

describe Chicago::Schema::PivotedColumn do
  before :each do
    @column = stub(:column)
    @pivot  = stub(:pivot)
  end
  
  it "has a nil group name" do
    described_class.new(@column, @pivot, 0, true).group_name.should be_nil
  end

  it "has a pair of labels as the label" do
    @column.stub(:label => :foo)
    described_class.new(@column, @pivot, 0, true).label.should == [:foo, true]
  end
end
