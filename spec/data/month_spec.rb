require "spec_helper"

describe Chicago::Data::Month do

  [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december].each do |month|
    it "should return a Month for #{month}" do
      Chicago::Data::Month.send(month).should be_kind_of(Chicago::Data::Month)
    end
  end

  it "should have a name" do
    Chicago::Data::Month.january.name.should == "January"
  end

  it "should return the name from #to_s" do
    Chicago::Data::Month.january.to_s.should == "January"
  end

  it "should have a short name" do
    Chicago::Data::Month.january.short_name.should == "Jan"
  end

  it "should have a number" do
    Chicago::Data::Month.january.to_i.should == 1
  end

  it "should return a date in a year" do
    Chicago::Data::Month.january.in(2009).should == Date.new(2009,1,1)
  end

  it "should be the same instance on mutliple calls to a month name" do
    Chicago::Data::Month.january.object_id.should == Chicago::Data::Month.january.object_id
  end

  it "should be comparable" do
    Chicago::Data::Month.january.should < Chicago::Data::Month.february
    Chicago::Data::Month.december.should > Chicago::Data::Month.january
  end

  it "should not be constructable" do
    lambda { Chicago::Data::Month("Foo", 13) }.should raise_error
  end

  it "should be parsable from a short string" do
    Chicago::Data::Month.parse("Jan").should == Chicago::Data::Month.january
  end

  it "should be parsable from a short string uncaptialized" do
    Chicago::Data::Month.parse("jan").should == Chicago::Data::Month.january
  end

  it "should be parsable from a full name" do
    Chicago::Data::Month.parse("December").should == Chicago::Data::Month.december
  end

  it "should be parsable from a full name uncaptialized" do
    Chicago::Data::Month.parse("january").should == Chicago::Data::Month.january
  end

  it "should be parsable from an integer" do
    Chicago::Data::Month.parse(1).should == Chicago::Data::Month.january
  end

  it "should return nil from a string that isn't a month name" do
    Chicago::Data::Month.parse("maybe").should == nil
  end
end
