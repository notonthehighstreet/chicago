require 'spec_helper'

describe Chicago::StarSchema do
  before :each do
    @schema = Chicago::StarSchema.new
  end

  describe "dimensions" do
    specify "are not defined initially" do
      @schema.dimensions.should be_empty
    end

    specify "can be defined" do
      @schema.define_dimension(:user).should be_kind_of(Chicago::Dimension)
      @schema.dimensions.should_not be_empty
    end

    specify "are not have mutable after definition" do
      @schema.define_dimension(:user)
      @schema.dimensions.clear
      @schema.dimensions.should_not be_empty
    end

    specify "are unique by name within a schema" do
      @schema.define_dimension(:user)
      expect { @schema.define_dimension(:user) }.
        to raise_error(Chicago::DuplicateTableError)
    end

    specify "can be defined with columns" do
      dimension = @schema.define_dimension(:user) do
        columns { string :email }
      end      
      dimension.should have_column_named(:email)
    end

    specify "can define columns in multiple blocks" do
      dimension = @schema.define_dimension(:user) do
        columns { string :email }
        columns { string :name }        
      end      
      dimension.should have_column_named(:name)
    end

    specify "can have a natural key defined" do
      dimension = @schema.define_dimension(:user) do
        columns { string :email }

        natural_key :email
      end      

      dimension.natural_key.should == [:email]
    end

    specify "can have null records defined" do
      dimension = @schema.define_dimension(:user) do
        columns { string :email }

        null_record :id => 1, :email => "Missing"
        null_record :id => 2, :email => "Not Applicable"
      end      

      db = stub(:db)
      db.stub_chain(:[], :insert_replace).and_return(db)
      db.should_receive(:insert_multiple).with([{:id => 1, :email => "Missing"},
                                                {:id => 2, :email => "Not Applicable"}])
      dimension.create_null_records(db)
    end

    specify "can be prebuilt and attached" do
      d = Chicago::Dimension.new(:foo)
      @schema.add(d)
      @schema.dimensions.should == [d]
    end
  end

  describe "shrunken dimensions" do
    specify "can be defined" do
      @schema.define_dimension(:date) do
        columns do
          integer :year
          integer :month
          integer :day
        end
      end

      @schema.define_shrunken_dimension(:month, :date) do
        columns :year, :month
      end.columns.map(&:name).should == [:year, :month]
    end

    specify "must have a subset of columns from the base dimension" do
      @schema.define_dimension(:date) do
        columns { integer :year }
      end

      expect {
        @schema.define_shrunken_dimension(:month, :date) do
          columns :year, :month
        end
      }.to raise_error(Chicago::MissingDefinitionError)
    end

    specify "raises an error if the base dimension is not defined" do
      expect {
        @schema.define_shrunken_dimension(:month, :date)
      }.to raise_error(Chicago::MissingDefinitionError)
    end
  end
  
  describe "facts" do
    specify "are not defined initially" do
      @schema.facts.should be_empty
    end

    specify "can be defined" do
      @schema.define_fact(:user).should be_kind_of(Chicago::Fact)
      @schema.facts.should_not be_empty
    end

    specify "are not have mutable after definition" do
      @schema.define_fact(:user)
      @schema.facts.clear
      @schema.facts.should_not be_empty
    end

    specify "are unique by name within a schema" do
      @schema.define_fact(:user)
      expect { @schema.define_fact(:user) }.
        to raise_error(Chicago::DuplicateTableError)
    end

    specify "can be prebuilt and attached" do
      f = Chicago::Fact.new(:foo)
      @schema.add(f)
      @schema.facts.should == [f]
    end

    specify "can be prebuilt and attached, but still must have unique names" do
      f = Chicago::Fact.new(:foo)
      f2 = Chicago::Fact.new(:foo)
      @schema.add(f)
      expect { @schema.add(f2) }.to raise_error(Chicago::DuplicateTableError)
    end

    specify "can have dimensions defined" do
      dim  = @schema.define_dimension(:date)
      fact = @schema.define_fact(:foo) do
        dimensions :date
      end
      fact.dimensions.should include(dim)
    end

    specify "raises an error if unspecified dimension is referenced" do
      expect { @schema.define_fact(:foo) { dimensions :date } }.
        to raise_error(Chicago::MissingDefinitionError)
    end

    specify "can have roleplayed dimensions defined, using Sequel's aliasing" do
      dim  = @schema.define_dimension(:date)
      fact = @schema.define_fact(:foo) do
        dimensions :date.as(:start_date)
      end
      fact.dimensions.map(&:name).should include(:start_date)
    end

    specify "can have degenerate dimensions defined" do
      fact = @schema.define_fact(:foo) do
        degenerate_dimensions do
          integer :reference_number
        end
      end
      fact.degenerate_dimensions.map(&:name).should include(:reference_number)
    end

    specify "can have measures defined" do
      fact = @schema.define_fact(:foo) do
        measures do
          integer :amount
        end
      end
      fact.measures.map(&:name).should include(:amount)
    end

    specify "allows defined measures to be null by default" do
      fact = @schema.define_fact(:foo) do
        measures { integer :amount }
      end
      fact.measures.first.should be_null
    end

    specify "can have a natural key defined" do
      dim  = @schema.define_dimension(:date)
      fact = @schema.define_fact(:foo) do
        dimensions :date

        natural_key :date
      end
      
      fact.natural_key.should == [:date]
    end
  end
  
  it "allows definition of a fact and a dimension with the same name" do
    @schema.define_fact(:user)
    expect { @schema.define_dimension(:user) }.
      to_not raise_error(Chicago::DuplicateTableError)
  end
end
