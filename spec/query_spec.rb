require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Query do
  def be_one_of(*args)
    simple_matcher("one of #{args.inspect}") {|given| args.include?(given) }
  end

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
      dimensions :customer, :product

      degenerate_dimensions do
        string :order_ref
      end

      measures do
        integer :total
        decimal :vat_rate, :semi_additive => true
      end
    end
  end

  it "should select the sum of a measure by default" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns :total
    q.dataset.opts[:select].should include(:sum[:total.qualify(:facts_sales)].as(:sum_total))
  end

  it "should select the average of a semi-additive measure by default" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns :vat_rate
    q.dataset.opts[:select].should include(:avg[:vat_rate.qualify(:facts_sales)].as(:avg_vat_rate))
  end

  it "should just select the column if a degenerate dimension" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns :order_ref
    q.dataset.opts[:select].should include(:order_ref.qualify(:facts_sales))
  end

  it "should make no difference if column names are strings not symbols" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'order_ref'
    q.dataset.opts[:select].should include(:order_ref.qualify(:facts_sales))
  end

  it "should select the dimension identifier if plain dimension is passed" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product'
    q.dataset.opts[:select].should include(:name.qualify(:dimension_product).as(:product))
  end

  it "should join on the dimension if necessary" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product'
    
    on_clause = [[Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id"),
                  Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id)]]
    join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)

    q.dataset.opts[:join].first.should == join_clause
  end

  it "should split a dimension column on '.' and select that column" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer'
    q.dataset.opts[:select].should include(:manufacturer.qualify(:dimension_product))
  end

  it "should join on a dimension if dimension column is included" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer'
    
    on_clause = [[Sequel::SQL::QualifiedIdentifier.new("dimension_product", "id"),
                  Sequel::SQL::QualifiedIdentifier.new(:facts_sales, :product_dimension_id)]]
    join_clause = Sequel::SQL::JoinOnClause.new(on_clause, :inner, :dimension_product)

    q.dataset.opts[:join].first.should == join_clause
  end

  it "should not attempt to join on a dimension multiple times" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer', 'product.type'

    q.dataset.opts[:join].first.table.should == :dimension_product
    q.dataset.opts[:join].size.should == 1
  end

  it "should group on a degenerate dimension column" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'order_ref'
    q.dataset.opts[:group].should == [:order_ref.qualify(:facts_sales)]
  end

  it "should group on a dimension column" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer'
    q.dataset.opts[:group].should == [:manufacturer.qualify(:dimension_product)]
  end

  it "should group on the original key instead of a main identifier column" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product'
    q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
  end

  it "should only group on dimension original key if plain dimension is used" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer', 'product', 'product.type'
    q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
  end

  it "should only group on dimension original key if dimension identifier is used" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer', 'product.name', 'product.type'
    q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product)]
  end

  it "should allow multiple calls to columns" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product'
    q.columns 'product.manufacturer'
    q.columns 'total'
    q.columns 'order_ref'

    q.dataset.opts[:select].should == [:name.qualify(:dimension_product).as(:product),
                                       :manufacturer.qualify(:dimension_product),
                                       :sum[:total.qualify(:facts_sales)].as(:sum_total),
                                       :order_ref.qualify(:facts_sales)]
    q.dataset.opts[:join].size.should == 1    
    q.dataset.opts[:group].should == [:original_id.qualify(:dimension_product), :order_ref.qualify(:facts_sales)]
  end

  it "shouldn't bother grouping on columns that are implied" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.manufacturer', 'product.manufacturer_address'
    q.dataset.opts[:group].should == [:manufacturer.qualify(:dimension_product)]
  end

  it "should group on at least one column out of 2 that imply each other" do
    q = Chicago::Query.new(TEST_DB, :sales)
    q.columns 'product.sku', 'product.internal_code'
    q.dataset.opts[:group].should be_one_of([:sku.qualify(:dimension_product)], [:internal_code.qualify(:dimension_product)])
  end
end
