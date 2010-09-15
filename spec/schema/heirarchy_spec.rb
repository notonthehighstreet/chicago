require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::Schema::HierarchicalElement do
  before :each do
    @h = Schema::Hierarchies.new
  end

  it "should have a factory method that returns a HierarchicalElement" do
    @h.element(:foo).should be_kind_of(Schema::HierarchicalElement)
  end

  it "should return the same element object" do
    @h.element(:foo).should === @h.element(:foo)
  end

  it "should have a name" do
    @h.element(:foo).name.should == :foo
  end

  it "should have a to_sym method" do
    @h.element(:foo).to_sym.should == :foo
  end
  
  it "should imply other elements" do
    @h.element(:foo).implies :bar, :baz
    @h.element(:foo).implications.map(&:to_sym).to_set.should == Set.new([:bar, :baz])
    @h.implications(:foo).map(&:to_sym).to_set.should == Set.new([:bar, :baz])
  end

  it "should imply other elements" do
    @h.element(:foo).implies :bar, :baz
    @h.element(:foo).implications.map(&:to_sym).to_set.should == Set.new([:bar, :baz])
    @h.implications(:foo).map(&:to_sym).to_set.should == Set.new([:bar, :baz])
  end

  it "should be transitive" do
    @h.element(:foo).implies :bar
    @h.element(:bar).implies :baz
    @h.implications(:foo).map(&:to_sym).to_set.should include(:baz)
  end

  it "should imply and be implied by other elements" do
    @h.element(:foo) <=> @h.element(:bar)
    @h.element(:foo).implications.map(&:to_sym).should == [:bar]
    @h.element(:bar).implications.map(&:to_sym).should == [:foo]
  end

  it "should deal with cycles in the implication graph" do
    @h.element(:foo).implies :bar
    @h.element(:bar).implies :baz
    @h.element(:baz).implies :foo
    @h.implications(:foo).to_set.should include(:baz, :bar)
  end


  it "should create hierarchy" do
    @h.element(:foo) > @h.element(:bar) > @h.element(:baz)
  end
end

describe Chicago::Schema::HierarchyBuilder do
  it "should build elements for any method call" do
    builder = Schema::HierarchyBuilder.new do
      foo
      bar
      id
    end
    Set.new(builder.__hierarchies.elements.map(&:to_sym)).should == Set.new([:foo, :bar, :id])
  end
end
