require 'spec_helper'

describe Chicago::Schema::Dimension do
  it_behaves_like "a named schema element"

  it "has a table name" do
    described_class.new(:foo).table_name.should == :dimension_foo
  end

  it "can have a description" do
    described_class.new(:foo, :description => "bar").description.should == "bar"
  end
  
  it "has columns" do
    column = stub(:column)
    described_class.new(:foo, :columns => [column]).
      columns.should == [column]
  end

  it "has no columns by default" do
    described_class.new(:foo).columns.should be_empty
  end

  it "can qualify a column" do
    described_class.new(:foo).qualify(stub(:column, :name => :bar)).
      should == :bar.qualify(:dimension_foo)
  end

  it "provides a hash-like accessor syntax for columns" do
    column = stub(:column, :name => :bar)
    dimension = described_class.new(:foo, :columns => [column])
    dimension[:bar].should == column
  end

  it "can have identifiers" do
    identifiers = [stub(:i), stub(:j)]
    described_class.new(:user, :identifiers => identifiers).
      identifiers.should == identifiers
  end
  
  it "can have a main identifier" do
    identifiers = [stub(:i), stub(:j)]
    described_class.new(:user, :identifiers => identifiers).
      main_identifier.should == identifiers.first
  end

  it "can create null records in the database, replacing existing records" do
    db = mock(:db)
    db.stub(:[]).and_return(db)
    db.should_receive(:insert_replace).and_return(db)
    db.should_receive(:insert_multiple).with([{:id => 1, :foo => :bar}])

    described_class.new(:user,
                           :null_records => [{ :id => 1,
                                               :foo => :bar}]).create_null_records(db)
  end

  it "should disallow null records without id fields" do
    expect do
      described_class.new(:user,
                             :null_records => [{:foo => :bar}])
    end.to raise_error(Chicago::UnsafeNullRecordError)
  end

  it "can define a natural key" do
    described_class.new(:user, :natural_key => [:foo, :bar]).
      natural_key.should == [:foo, :bar]
  end

  it "supports column_definitions [DEPRECATED]" do
    dimension = described_class.new(:user, :natural_key => [:foo, :bar])
    dimension.columns.should == dimension.column_definitions
  end

  it "supports original_key if it has an original_id column [DEPRECATED]" do
    column = stub(:c, :name => :original_id)
    described_class.new(:user, :columns => [column]).original_key.should == column
  end

  it "is considered identifiable if it has an original key [DEPRECATED]" do
    column = stub(:c, :name => :original_id)
    described_class.new(:user, :columns => [column]).should be_identifiable
  end

  it "can have predetermined values" do
    described_class.new(:countries, :predetermined_values => true).should have_predetermined_values
  end
  
  it "is visitable" do
    visitor = mock(:visitor)
    dimension = described_class.new(:foo)
    visitor.should_receive(:visit_dimension).with(dimension)
    dimension.visit(visitor)
  end
end
