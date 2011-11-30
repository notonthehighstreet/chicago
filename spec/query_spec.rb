require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe Chicago::Query do
  before :all do
    Chicago::Schema::Dimension.define(:product) do
      columns do
        integer :original_id
        string :name
        string :manufacturer
        string :manufacturer_address
        string :type
        string :sku
        string :internal_code
      end

      hierarchies do
        manufacturer.implies manufacturer_address
        sku <=> internal_code
      end

      identified_by :name
    end

    Chicago::Schema::Fact.define(:sales) do
      dimensions :product

      degenerate_dimensions do
        string :order_ref
      end

      measures do
        integer :total
        decimal :vat_rate, :semi_additive => true
      end
    end
  end

  after :all do
    Chicago::Schema::Dimension.clear_definitions
    Chicago::Schema::Fact.clear_definitions
  end

  describe "#select" do
    it "allows chained method calls" do
      Chicago::Query.fact(TEST_DB, :sales).select(:total).should be_kind_of(Chicago::Query)
    end
    
    it "selects the sum of a measure by default" do
      q = Chicago::Query.fact(TEST_DB, :sales).select(:total)
      q.dataset.opts[:select].should include(:sum[:total.qualify(:facts_sales)].as(:sum_total))
    end

    it "selects the average of a semi-additive measure by default" do
      q = Chicago::Query.fact(TEST_DB, :sales).select(:vat_rate)
      q.dataset.opts[:select].should include(:avg[:vat_rate.qualify(:facts_sales)].as(:avg_vat_rate))
    end

    it "selects the column, qualified to the fact table, if a degenerate dimension" do
      q = Chicago::Query.fact(TEST_DB, :sales).select(:order_ref)
      q.dataset.opts[:select].should include(:order_ref.qualify(:facts_sales))
    end

    it "is indifferent to being passed Strings or Symbols" do
      q = Chicago::Query.fact(TEST_DB, :sales).select('order_ref')
      q.dataset.opts[:select].should include(:order_ref.qualify(:facts_sales))
    end

    it "selects the dimension identifier if plain dimension is passed" do
      q = Chicago::Query.fact(TEST_DB, :sales).select('product')
      q.dataset.opts[:select].should include(:name.qualify(:dimension_product).as(:product))
    end

    it "splits a dimension column on '.' and select that column" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer'
      q.dataset.opts[:select].should include(:manufacturer.qualify(:dimension_product))
    end

    it "joins on the dimension if the dimension is selected" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product'
    
      on_clause = make_on_clause(Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id") =>
                                 Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id))
      join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)
      
      q.dataset.opts[:join].first.should == join_clause
    end

    it "joins on the dimension if dimension column is included" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer'
    
      on_clause = make_on_clause(Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id") =>
                                 Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id))
      
      join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)
      
      q.dataset.opts[:join].first.should == join_clause
    end

    it "should not attempt to join on a dimension multiple times" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer', 'product.type'
      
      q.dataset.opts[:join].first.table.should == :dimension_product
      q.dataset.opts[:join].size.should == 1
    end

    it "groups on a degenerate dimension column" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'order_ref'
      q.dataset.opts[:group].should == [:order_ref.qualify(:facts_sales)]
    end

    it "groups on a dimension column" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer'
      q.dataset.opts[:group].should == [:manufacturer.qualify(:dimension_product)]
    end

    it "groups on the original key instead of a main identifier column" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product'
      q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
    end

    it "should only group on dimension original key if plain dimension is used" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer', 'product', 'product.type'
      q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
    end

    it "should only group on dimension original key if dimension identifier is used" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer', 'product.name', 'product.type'
      q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
    end
    
    it "allows multiple calls without overwriting previous column selections" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product'
      q.select 'product.manufacturer'
      q.select 'total'
      q.select 'order_ref'

      q.dataset.opts[:select].should == [:name.qualify(:dimension_product).as(:product),
                                         :manufacturer.qualify(:dimension_product),
                                         :sum[:total.qualify(:facts_sales)].as(:sum_total),
                                         :order_ref.qualify(:facts_sales)]
      q.dataset.opts[:join].size.should == 1    
      q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product), :order_ref.qualify(:facts_sales)]
    end

    it "doesn't group on columns that are implied by columns already grouped" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.manufacturer', 'product.manufacturer_address'
      q.dataset.opts[:group].should == [:manufacturer.qualify(:dimension_product)]
    end

    it "groups on at least one column out of 2 that imply each other" do
      q = Chicago::Query.fact(TEST_DB, :sales)
      q.select 'product.sku', 'product.internal_code'
      q.dataset.opts[:group].should be_one_of([:sku.qualify(:dimension_product)], [:internal_code.qualify(:dimension_product)])
    end
  end

  describe "#columns" do
    it "returns an empty array if no columns are selected" do
      Chicago::Query.fact(TEST_DB, :sales).columns.should be_empty
    end
    
    it "returns degenerate dimensions" do
      Chicago::Query.fact(TEST_DB, :sales).select(:order_ref).columns.
        should == [Chicago::Schema::Fact[:sales][:order_ref]]
    end

    it "returns dimension columns" do
      Chicago::Query.fact(TEST_DB, :sales).select("product.name").columns.
        should == [Chicago::Schema::Dimension[:product][:name]]
    end

    it "returns measure columns" do
      Chicago::Query.fact(TEST_DB, :sales).select("total").columns.
        should == [Chicago::Schema::Fact[:sales][:total]]
    end

    it "returns the main identifier for bare dimensions" do
      column = Chicago::Query.fact(TEST_DB, :sales).select("product").columns.first
      
      column.label.should == "Product"
      column.name.should == :product
      column.to_s.should == "product"
      column.sql_name.should == :name.qualify(:dimension_product).as("product")
    end
  end
  
  describe "ordering" do
    it "can be ordered by a dimension column" do
      q = Chicago::Query.fact(TEST_DB, :sales).order('product.sku')
      q.dataset.opts[:order].should == [:sku.qualify(:dimension_product)]
    end
  end
  
  private

  def make_on_clause(hash)
    Sequel::SQL::BooleanExpression.from_value_pairs(hash, "=")
  end
end
