shared_examples_for "a column" do
  it "has a human-friendly label" do
    subject.label.should == "User Name"
  end

  it "should have a name" do
    subject.name.should == :user_name
  end

  it "should have a column type" do
    subject.column_type.should == :string
  end
end
