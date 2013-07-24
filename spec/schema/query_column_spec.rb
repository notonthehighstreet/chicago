require 'spec_helper'
require 'chicago/schema/query_column'

describe Chicago::Schema::QueryColumn do
  describe "a standard column" do
    let(:owner) { stub(:owner).as_null_object }
    let(:column) { stub(:column, :calculated? => false).as_null_object }
    subject { described_class.column(owner, column, "foo.bar") }
    
    it "should have a column alias" do
      subject.column_alias.should == "foo.bar"
    end

    it "has an owner" do
      subject.owner.should == owner
    end

    it "has a sequel qualified name for use in SELECT statements" do
      owner.stub(:name).and_return(:foo)
      column.stub(:name).and_return(:bar)
      subject.select_name.should == :bar.qualify(:foo)
    end

    it "has a sequel qualified name for use in COUNT" do
      owner.stub(:name).and_return(:foo)
      column.stub(:name).and_return(:bar)
      subject.count_name.should == :bar.qualify(:foo)
    end

    it "uses the alias in GROUP BY" do
      subject.group_name.should == :"foo.bar"
    end

    it "delegates label to the decorated column" do
      column.should_receive(:label).and_return("Bar")
      subject.label.should == "Bar"
    end
  end

  describe "a virtual column generated from calculation" do
    let(:calculation) { stub(:calculation).as_null_object }
    let(:owner) { stub(:owner).as_null_object }
    let(:column) { stub(:column, :calculated? => true, :calculation => calculation).as_null_object }
    subject { described_class.column(owner, column, "foo.bar") }

    it "should have a column alias" do
      subject.column_alias.should == "foo.bar"
    end

    it "has an owner" do
      subject.owner.should == owner
    end

    it "has a sequel qualified name for use in SELECT statements" do
      owner.stub(:name).and_return(:foo)
      column.stub(:name).and_return(:bar)
      subject.select_name.should == calculation
    end

    it "not be grouped" do
      subject.group_name.should be_nil
    end

    it "delegates label to the decorated column" do
      column.should_receive(:label).and_return("Bar")
      subject.label.should == "Bar"
    end
  end

  describe "a dimension column" do
    let(:owner) { stub(:owner).as_null_object }
    let(:column) { stub(:column).as_null_object }
    subject { described_class.column(owner, column, "foo.bar") }

    before :each do
      column.stub(:main_identifier).and_return(:name)
      column.stub(:original_key).and_return(stub(:name => :original_id))
      column.stub(:kind_of?).with(Chicago::Schema::Dimension).and_return(true)
    end
    
    it "should have a column alias" do
      subject.column_alias.should == "foo.bar"
    end

    it "has an owner" do
      subject.owner.should == owner
    end

    it "uses the main identifier in SELECT statements" do
      column.stub(:name).and_return(:bar)
      subject.select_name.should == :name.qualify(:bar)
    end

    it "uses the original id in COUNT" do
      column.stub(:name).and_return(:bar)
      subject.count_name.should == :original_id.qualify(:bar)
    end

    it "uses the original id in GROUP BY" do
      column.stub(:name).and_return(:bar)
      subject.group_name.should == :original_id.qualify(:bar)
    end

    it "delegates label to the decorated column" do
      column.should_receive(:label).and_return("Bar")
      subject.label.should == "Bar"
    end
  end

  describe "a dimension identifier column" do
    let(:owner) { stub(:owner).as_null_object }
    let(:column) { stub(:column).as_null_object }
    subject { described_class.column(owner, column, "foo.bar") }

    before :each do
      column.stub(:name).and_return(:bar)

      owner.stub(:name).and_return(:foo)
      owner.stub(:original_key).and_return(stub(:name => :original_id))
      owner.stub(:kind_of?).with(Chicago::Schema::Dimension).and_return(true)
      owner.stub(:identifiable?).and_return(true)
      owner.stub(:identifiers).and_return([:bar])
    end
    
    it "should have a column alias" do
      subject.column_alias.should == "foo.bar"
    end

    it "has an owner" do
      subject.owner.should == owner
    end

    it "uses the name in SELECT statements" do
      subject.select_name.should == :bar.qualify(:foo)
    end

    it "uses the original id in COUNT" do
      subject.count_name.should == :original_id.qualify(:foo)
    end

    it "uses the original id in GROUP BY" do
      subject.group_name.should == :original_id.qualify(:foo)
    end

    it "delegates label to the decorated column" do
      column.should_receive(:label).and_return("Bar")
      subject.label.should == "Bar"
    end
  end
end
