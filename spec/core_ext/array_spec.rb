require "spec_helper"

describe "Array#condense" do
  it "should return [1,2,3] from [1,2,3]" do
    x = [1,2,3]
    x.condense.should == x
  end

  it "should return [1] from [1]" do
    x = [1]
    x.condense.should == x
  end

  it "should return [1,2,3] from [[1,2,3]]" do
    x = [[1,2,3]]
    x.condense.should == [1,2,3]
  end

  it "should return [1,2,3] from [[[[1,2,3]]]]" do
    x = [[[[1,2,3]]]]
    x.condense.should == [1,2,3]
  end

  it "should return [[[1,2]],3] from [[[1,2]],3]" do
    x = [[[1,2]],3]
    x.condense.should == x
  end

  it "should return [[1,2],3] from [[[1,2],3]]" do
    x = [[[1,2],3]]
    x.condense.should == [[1,2],3]
  end
end
