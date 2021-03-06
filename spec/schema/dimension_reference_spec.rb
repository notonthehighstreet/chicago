require 'spec_helper'

describe Chicago::Schema::DimensionReference do
  before :each do
    @dimension = Chicago::Schema::Dimension.new(:bar, :null_records => [{:id => 1}])
  end

  it "returns columns from the dimension" do
    @dimension.should_receive(:columns).and_return(:result)
    described_class.new(:foo, @dimension).columns.should == :result
  end

  it "returns columns via column_definitions [DEPRECTAED]" do
    @dimension.should_receive(:column_definitions).and_return(:result)
    described_class.new(:foo, @dimension).column_definitions.
      should == :result
  end

  it "returns identifiers from the dimension" do
    @dimension.should_receive(:identifiers).and_return(:result)
    described_class.new(:foo, @dimension).identifiers.should == :result
  end

  it "returns main identifier from the dimension" do
    @dimension.should_receive(:main_identifier).and_return(:result)
    described_class.new(:foo, @dimension).main_identifier.should == :result
  end

  it "returns identifiable? from the dimension" do
    @dimension.should_receive(:identifiable?).and_return(true)
    described_class.new(:foo, @dimension).should be_identifiable
  end

  it "returns original_key from the dimension" do
    @dimension.should_receive(:original_key).and_return(:result)
    described_class.new(:foo, @dimension).original_key.should == :result
  end

  it "returns countable from the dimension" do
    @dimension.should_receive(:countable?).and_return(true)
    described_class.new(:foo, @dimension).should be_countable
  end

  it "has a countable label" do
    described_class.new(:foo, @dimension).countable_label.
      should == "No. of Foos"
  end

  it "returns natural_key from the dimension" do
    @dimension.should_receive(:natural_key).and_return(:result)
    described_class.new(:foo, @dimension).natural_key.should == :result
  end

  it "returns [] from the dimension" do
    @dimension.should_receive(:[]).with(:bar).and_return(:result)
    described_class.new(:foo, @dimension)[:bar].should == :result
  end

  it "has a table name from the dimension" do
    @dimension.should_receive(:table_name).and_return(:result)
    described_class.new(:foo, @dimension).table_name.should == :result
  end

  it "has a minimum of 0" do
    described_class.new(:foo, @dimension).min.should == 0
  end

  it "should have a column_type of integer" do
    described_class.new(:foo, @dimension).column_type.should == :integer
  end

  it "has the key column as the database name" do
    described_class.new(:foo, @dimension).database_name.
      should == :foo_dimension_id
  end

  it "qualfies a column based on the column name" do
    column = double(:column, :name => :baz)
    column.should_receive(:qualify_by).with(:dimension_foo)
    described_class.new(:foo, @dimension).qualify(column)
  end

  it "can be qualified, and qualifies the key name" do
    described_class.new(:foo, @dimension).qualify_by(:facts_bar).
      should == :foo_dimension_id.qualify(:facts_bar)
  end

  it "should be considered a kind of dimension" do
    described_class.new(:foo, @dimension).should be_kind_of(Chicago::Schema::Dimension)
  end

  it "can override the key selected as the reference" do
    described_class.new(:foo, @dimension, :key_name => :baz_dimension_id).
      database_name.should ==:baz_dimension_id
  end

  it "uses the first null record id as the default value" do
    described_class.new(:foo, @dimension).default_value.should == 1
  end

  it "knows whether it is a roleplayed dimension or not" do
    expect(described_class.new(:bar, @dimension)).to_not be_roleplayed
    expect(described_class.new(:foo, @dimension)).to be_roleplayed
  end

  it "is visitable" do
    visitor = double(:visitor)
    column = described_class.new(:foo, @dimension)
    visitor.should_receive(:visit_dimension_reference).with(column)
    column.visit(visitor)
  end
end
