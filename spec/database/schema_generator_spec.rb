require 'spec_helper'
require 'chicago/database/schema_generator'

describe Chicago::Database::SchemaGenerator do
  subject { described_class.new(Chicago::Database::ConcreteSchemaStrategy.new) }
  
  it_behaves_like "a schema visitor"
  
  describe "#visit_fact" do
    before :all do
      schema = Chicago::StarSchema.new
      schema.define_dimension :customer
      schema.define_dimension :product      
      @fact = schema.define_fact(:sales) do
        dimensions :customer, :product
        degenerate_dimensions { string :reference }
        measures { 
          integer :quantity 
          integer :calculated, :calculation => 1 + 1
        }
        natural_key :customer, :reference
      end
    end
    
    it "should define a sales_facts table" do
      subject.visit_fact(@fact).should have_key(:facts_sales)
    end

    it "should have an unsigned integer :id column" do
      expected = {:name => :id, :column_type => :integer, :unsigned => true}
      subject.visit_fact(@fact)[:facts_sales][:columns].
        should include(expected)
    end

    it "should define :id as the primary key" do
      subject.visit_fact(@fact)[:facts_sales][:primary_key].should == [:id]
    end

    it "should include a hash of table options" do
      subject.visit_fact(@fact)[:facts_sales][:table_options].should == {}
    end

    it "should have a table type of MyISAM for mysql" do
      subject.database_strategy = Chicago::Database::MysqlStrategy.new
      subject.visit_fact(@fact)[:facts_sales][:table_options].should == {:engine => "myisam"}
    end

    it "should output the dimension foreign key columns" do
      [{:name => :customer_dimension_id, :column_type => :integer, :unsigned => true, :null => false},
       {:name => :product_dimension_id, :column_type => :integer, :unsigned => true, :null => false}
      ].each do |column|
        subject.visit_fact(@fact)[:facts_sales][:columns].should include(column)
      end
    end

    it "should output the degenerate dimension columns" do
      subject.visit_fact(@fact)[:facts_sales][:columns].should include({:name => :reference, :column_type => :varchar, :null => false})
    end

    it "should output the measure columns" do
      subject.visit_fact(@fact)[:facts_sales][:columns].should include({:name => :quantity, :column_type => :integer, :null => true, :unsigned => false})
    end

    it "should not output calculated columns" do
      subject.visit_fact(@fact)[:facts_sales][:columns].any? {|c| c[:name] == :calculated }.should_not eql(true)
    end

    it "should define non-unique indexes for every dimension" do
      subject.visit_fact(@fact)[:facts_sales][:indexes].should == {
        :_inserted_at_idx => { :columns => :_inserted_at, :unique => false },
        :product_idx => { :columns => :product_dimension_id, :unique => false },
        :customer_idx => { :columns => [:customer_dimension_id, :reference], :unique => true },
        :reference_idx => { :columns => :reference, :unique => false }
      }
    end

    it "has an inserted at column" do
      subject.visit_fact(@fact)[:facts_sales][:columns].
        should include(:name => :_inserted_at, :column_type => :timestamp, :null => true)
    end
  end

  describe "#visit_dimension" do
    before :each do
      @schema = Chicago::StarSchema.new
    end

    it "should define a user_dimension table" do
      @dimension = @schema.define_dimension(:user)
      subject.visit_dimension(@dimension).keys.should include(:dimension_user)
    end

    it "should have an unsigned integer :id column" do
      @dimension = @schema.define_dimension(:user)
      expected = {:name => :id, :column_type => :integer, :unsigned => true}
      subject.visit_dimension(@dimension)[:dimension_user][:columns].should include(expected)
    end

    it "should define :id as the primary key" do
      @dimension = @schema.define_dimension(:user)
      subject.visit_dimension(@dimension)[:dimension_user][:primary_key].should == [:id]
    end

    it "should include a hash of table options" do
      @dimension = @schema.define_dimension(:user)
      subject.visit_dimension(@dimension)[:dimension_user][:table_options].should == {}
    end

    it "should have a table type of MyISAM for mysql" do
      @dimension = @schema.define_dimension(:user)
      subject.database_strategy = Chicago::Database::MysqlStrategy.new
      subject.visit_dimension(@dimension)[:dimension_user][:table_options].should == {:engine => "myisam"}
    end

    it "should include the sequel schema for the defined columns" do
      @dimension = @schema.define_dimension(:user) do
        columns do
          string :username, :max => 10
        end
      end

      expected = {:name => :username, :column_type => :varchar, :size => 10, :null => false}
      subject.visit_dimension(@dimension)[:dimension_user][:columns].should include(expected)
    end

    it "should output indexes for every column that isn't descriptive" do
      @dimension = @schema.define_dimension(:user) do
        columns do
          string :foo, :descriptive => true
          string :bar
          string :baz, :unique => true
        end
      end

      expected = {
        :_inserted_at_idx => { :columns => :_inserted_at, :unique => false },
        :bar_idx => {:columns => :bar, :unique => false},
        :baz_idx => {:columns => :baz, :unique => true}
      }
      subject.visit_dimension(@dimension)[:dimension_user][:indexes].should == expected
    end

    it "should output a natural_key unique index for the natural key" do
      @dimension = @schema.define_dimension(:user) do
        columns do
          string :foo, :descriptive => true
          string :bar
          string :baz
        end
        natural_key :bar, :baz
      end

      expected = {
        :_inserted_at_idx => { :columns => :_inserted_at, :unique => false },
        :bar_idx => {:columns => [:bar, :baz], :unique => true}, 
        :baz_idx => {:columns => :baz, :unique => false}
      }
      subject.visit_dimension(@dimension)[:dimension_user][:indexes].should == expected
    end

    # This just supports internal convention at the moment
    it "should create a key mapping table if an original_id column is present" do
      @dimension = @schema.define_dimension(:user) do
        columns do
          integer :original_id, :min => 0
          string :username, :max => 10
        end
      end

      key_table = subject.visit_dimension(@dimension)[:keys_dimension_user]
      key_table.should_not be_nil
      key_table[:primary_key].should == [:original_id]

      expected = [{:name => :original_id, :column_type => :integer, :null => false, :unsigned => true},
                  {:name => :dimension_id, :column_type => :integer, :null => false, :unsigned => true}]
      key_table[:columns].should == expected
    end

    it "creates a mapping table with a binary column, for dimensions with no original_id" do
      @dimension = @schema.define_dimension(:user) do
        columns do
          string :username, :max => 10
          natural_key :username
        end
      end

      key_table = subject.visit_dimension(@dimension)[:keys_dimension_user]
      key_table.should_not be_nil
      key_table[:primary_key].should == [:original_id]

      expected = [{:name => :original_id, :column_type => :binary, :null => false, :size => 16},
                  {:name => :dimension_id, :column_type => :integer, :null => false, :unsigned => true}]
      key_table[:columns].should == expected
    end

    it "doesn't create a key table for static dimensions" do
      @dimension = @schema.define_dimension(:currency) do
        has_predetermined_values

        columns do
          string :currency
        end
      end

      subject.visit_dimension(@dimension)[:keys_dimension_currency].should be_nil
    end

    it "has an inserted at column" do
      @dimension = @schema.define_dimension(:user)
      subject.visit_dimension(@dimension)[:dimension_user][:columns].
        should include(:name => :_inserted_at, :column_type => :timestamp, :null => true)
    end
  end
end
