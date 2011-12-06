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

    Chicago::Schema::Dimension.define(:customer) do
      columns do
        string :name
      end
    end
    
    Chicago::Schema::Fact.define(:sales) do
      dimensions :product, :customer

      degenerate_dimensions do
        string :order_ref
      end

      measures do
        integer :total
        decimal :vat_rate, :semi_additive => true
      end
    end
  end

  describe "#select" do
    before :each do
      @q = Chicago::Query.fact(TEST_DB, :sales)
    end
    
    it "allows chained method calls" do
      @q.select("product.name").should be_kind_of(Chicago::Query)
    end
    
    it "selects the sum of a measure" do
      @q.select("sum.sales.total")
      @q.dataset.opts[:select].should include(:sum[:total.qualify(:facts_sales)].as("sum.sales.total"))
    end

    it "selects the column, qualified to the fact table, if a degenerate dimension" do
      @q.select("sales.order_ref")
      @q.dataset.opts[:select].should include(:order_ref.qualify(:facts_sales).as("sales.order_ref"))
    end

    it "selects the dimension identifier if plain dimension is passed" do
      @q.select('product')
      @q.dataset.opts[:select].should include(:name.qualify(:dimension_product).as("product"))
    end

    it "selects a dimension column" do
      @q.select 'product.manufacturer'
      @q.dataset.opts[:select].should include(:manufacturer.qualify(:dimension_product).as("product.manufacturer"))
    end

    it "joins on the dimension if the dimension is selected" do
      @q.select 'product'
    
      on_clause = make_on_clause(Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id") =>
                                 Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id))
      join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)
      
      @q.dataset.opts[:join].first.should == join_clause
    end

    it "joins on the dimension if dimension column is included" do
      @q.select 'product.manufacturer'
    
      on_clause = make_on_clause(Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id") =>
                                 Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id))
      
      join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)
      
      @q.dataset.opts[:join].first.should == join_clause
    end

    it "should not attempt to join on a dimension multiple times" do
      @q.select 'product.manufacturer', 'product.type'      
      @q.dataset.opts[:join].map(&:table).should == [:dimension_product]
    end

    it "doesn't try to join on the fact table" do
      @q.select 'product.manufacturer', 'sum.sales.total'
      @q.dataset.opts[:join].map(&:table).should == [:dimension_product]
    end

    it "joins on multiple dimensions" do
      @q.select 'product.manufacturer', 'customer.name'
      @q.dataset.opts[:join].map(&:table).should == [:dimension_product, :dimension_customer]
    end
    
    it "groups on a degenerate dimension column" do
      @q.select 'sales.order_ref'
      @q.dataset.opts[:group].should == ['sales.order_ref'.to_sym]
    end

    it "groups on a dimension column" do
      @q.select 'product.manufacturer'
      @q.dataset.opts[:group].should == ['product.manufacturer'.to_sym]
    end

    it "groups on the original key instead of a main identifier column" do
      Chicago::Schema::Dimension[:product].original_key.should_not be_nil
      @q.select 'product'
      @q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
    end

    it "only groups on dimension original key if plain dimension is used" do
      @q.select 'product.manufacturer', 'product', 'product.type', 'customer.name'
      @q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product),
                                         :'customer.name']
    end

    it "doesn't group on calculated columns" do
      @q.select 'product', 'sum.sales.total'
      @q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
    end
    
    it "allows multiple calls without overwriting previous column selections" do
      @q.select 'product'
      @q.select 'product.manufacturer'
      @q.select 'sum.sales.total'
      @q.select 'sales.order_ref'
      
      @q.dataset.opts[:select].should == [:name.qualify(:dimension_product).as('product'),
                                         :manufacturer.qualify(:dimension_product).as('product.manufacturer'),
                                         :sum[:total.qualify(:facts_sales)].as('sum.sales.total'),
                                         :order_ref.qualify(:facts_sales).as('sales.order_ref')]
      @q.dataset.opts[:join].size.should == 1    
      @q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product),
                                         :'sales.order_ref']
    end

    it "doesn't group on columns that are implied by columns already grouped" do
      pending
      @q.select 'product.manufacturer', 'product.manufacturer_address'
      @q.dataset.opts[:group].should == [:'product.manufacturer']
    end

    it "groups on at least one column out of 2 that imply each other" do
      pending
      @q.select 'product.sku', 'product.internal_code'
      @q.dataset.opts[:group].should be_one_of([:sku.qualify(:dimension_product)], [:internal_code.qualify(:dimension_product)])
    end
  end

  describe "#columns" do
    before :each do
      @q = Chicago::Query.fact(TEST_DB, :sales)
    end
    
    it "returns an empty array if no columns are selected" do
      @q.columns.should be_empty
    end
    
    it "returns degenerate dimensions" do
      @q.select('sales.order_ref').columns.
        should == [Chicago::Schema::Fact[:sales][:order_ref]]
    end

    it "returns dimension columns" do
      @q.select("product.name").columns.
        should == [Chicago::Schema::Dimension[:product][:name]]
    end

    it "returns measure columns" do
      column = @q.select("sum.sales.total").columns.first
      column.label.should == "Total"
      column.qualified_name.should == "sum.sales.total"
    end

    it "returns the main identifier for bare dimensions" do
      column = @q.select("product").columns.first
      column.label.should == "Product"
      column.qualified_name.should == "product"
    end
  end
  
  describe "ordering" do
    before :each do
      @q = Chicago::Query.fact(TEST_DB, :sales)
    end

    it "can be ordered by a dimension column" do
      @q.select('product.sku').order('product.sku')
      @q.dataset.opts[:order].should == ['product.sku']
    end

    it "can be ordered by a column not part of the select" do
      @q.order('product.sku')
      @q.dataset.opts[:order].should == [:sku.qualify(:dimension_product)]
    end

    it "can be ordered by a bare dimension not part of the select" do
      @q.order('product')
      @q.dataset.opts[:order].should == [:name.qualify(:dimension_product)]
    end
  end

  describe "filtering" do
    before :each do
      @q = Chicago::Query.fact(TEST_DB, :sales)
    end

    it "should use a FilterStringParser" do
      parser = mock(:parser)
      parser.should_receive(:apply_to).with(kind_of(Sequel::MySQL::Dataset)).and_return(stub(:dataset))

      Chicago::FilterStringParser.should_receive(:new).with("filters").and_return(parser)

      @q.filter("filters").should == @q
    end
  end
  
  describe "#limit" do
    it "delegates limiting to the underlying Sequel Dataset" do
      dataset = mock(:dataset)
      stub_db = stub(:database, :[] => dataset)

      dataset.should_receive(:limit).with(10)
      Chicago::Query.fact(stub_db, :sales).limit(10)
    end
  end
  
  private

  def make_on_clause(hash)
    Sequel::SQL::BooleanExpression.from_value_pairs(hash, "=")
  end
end
