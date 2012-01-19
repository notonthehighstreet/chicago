shared_examples_for "a schema visitor" do
  it "supports visit_measure" do
    subject.should respond_to(:visit_measure)
  end

  it "supports visit_degenerate_dimension" do
    subject.should respond_to(:visit_degenerate_dimension)
  end

  it "supports visit_dimension_reference" do
    subject.should respond_to(:visit_dimension_reference)
  end

  it "supports visit_column" do
    subject.should respond_to(:visit_column)
  end
  
  it "supports visit_dimension" do
    subject.should respond_to(:visit_dimension)
  end

  it "supports visit_fact" do
    subject.should respond_to(:visit_fact)
  end

  it "supports traverse" do
    subject.should respond_to(:traverse)
  end
end
