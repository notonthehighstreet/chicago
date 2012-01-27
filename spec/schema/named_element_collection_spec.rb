require 'spec_helper'

describe Chicago::Schema::NamedElementCollection do
  before :each do
    @e = stub(:element, :name => :foo)
  end
  
  it "supports adding an element via add" do
    subject.add(@e)
    subject.to_a.should == [@e]
  end

  it "supports adding an element via <<" do
    subject << @e
    subject.to_a.should == [@e]
  end

  it "returns the element just added" do
    subject.add(@e).should == @e
  end

  it "can be iterated over" do
    subject.add(@e)
    subject.each {|element| element.should == @e }
  end

  it "is enumerable" do
    subject.should be_kind_of(Enumerable)
  end

  it "supports access by name" do
    subject.add @e
    subject[:foo].should == @e
  end

  it "returns true from contains? if the collection contains the same-named element" do
    subject.add @e
    subject.contain?(stub(:element, :name => :foo)).should be_true
    subject.contain?(stub(:element, :name => :bar)).should be_false    
  end

  it "returns the number of elements in a collection from size" do
    subject.add @e
    subject.size.should == 1
  end

  it "returns the number of elements in a collection from length" do
    subject.add @e
    subject.length.should == 1
  end

  it "responds to empty?" do
    subject.should be_empty
    subject.add @e
    subject.should_not be_empty
  end

  it "can be constructed with a list of elements" do
    described_class.new(@e).contain?(@e).should be_true
  end

  it "has elements that are unique by name" do
    subject.add(@e)
    subject.add(stub(:element, :name => :foo))
    subject.size.should == 1
  end
end
