shared_examples_for "a named schema element" do
  it "has a name" do
    described_class.new(:foo).name.should == :foo
  end

  it "casts the name to a Symbol" do
    described_class.new('foo').name.should == :foo
  end
  
  it "has a human-friendly label" do
    described_class.new(:foo).label.should == "Foo"
  end

  it "can have an explicitly defined human-friendly label" do
    described_class.new(:foo, :label => "Bar").label.should == "Bar"
  end
end
