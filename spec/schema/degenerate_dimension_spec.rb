require 'spec_helper'

describe Chicago::Schema::DegenerateDimension do
  subject { described_class.new(:user_name, :string) }

  it_behaves_like "a column"

  it "is visitable" do
    visitor = mock(:visitor)
    column = described_class.new(:foo, :integer)
    visitor.should_receive(:visit_degenerate_dimension).with(column)
    column.visit(visitor)
  end
end
