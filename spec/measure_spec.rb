require 'spec_helper'

describe Chicago::Measure do
  subject { described_class.new(:user_name, :string) }

  it_behaves_like "a column"

  it "should not be semi_additive by default" do
    described_class.new(:rate, :integer).should_not be_semi_additive
  end
  
  it "can be defined as semi_additive" do
    described_class.new(:rate, :integer, :semi_additive => true).
      should be_semi_additive
  end

  it "is visitable" do
    visitor = mock(:visitor)
    measure = described_class.new(:foo, :integer)
    visitor.should_receive(:visit_measure).with(measure)
    measure.visit(visitor)
  end
end
