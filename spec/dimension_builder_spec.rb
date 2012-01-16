require 'spec_helper'

describe Chicago::Schema::Builders::DimensionBuilder do
  before :each do
    @builder = described_class.new(stub())
  end

  it "builds a dimension" do
    @builder.build("foo").should be_kind_of(Chicago::Dimension)
  end
  
  it "builds a dimension with a name" do
    @builder.build("foo").name.should == :foo
  end

  it "can have a column builder specified" do    
    @builder.column_builder = Class.new do
      def build
        [:column] if block_given?
      end
    end

    @builder.build(:foo) do
      columns do
        # No op
      end
    end.columns.should == [:column]
  end
end
