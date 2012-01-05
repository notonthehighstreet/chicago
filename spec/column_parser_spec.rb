require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

describe "Parsing column strings" do
  before :all do
    Chicago::Schema::Dimension.define(:date) do
      columns do
        date :date
        integer :year
      end

      identified_by :date
    end
    
    Chicago::Schema::Dimension.define(:product) do
      columns do
        integer :original_id
        string :name
        string :manufacturer
      end

      identified_by :name
    end

    Chicago::Schema::Fact.define(:sales) do
      dimensions :product, :sale_date => :date, :ship_date => :date

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
  
  before :each do
    @fact = Chicago::Schema::Fact[:sales]
    @dimension = Chicago::Schema::Fact[:product]
  end
  
  it "returns a column from a dimension" do
    column = parse_column(@fact, "product.manufacturer")

    column.name.should == :manufacturer
    column.sql_name.should == :manufacturer.qualify(:dimension_product).as('product.manufacturer')
    column.qualified_name.should == 'product.manufacturer'
  end

  it "raises an InvalidDimension error if an invalid dimension is passed" do
    lambda {
      parse_column(@fact, "customer.name")
    }.should raise_error(Chicago::Schema::InvalidDimensionError)
  end

  it "raises an InvalidColumn error if an invalid column is selected" do
    lambda {
      parse_column(@fact, "product.foo")
    }.should raise_error(Chicago::Schema::InvalidColumnError)
  end

  it "returns a degenerate dimension" do
    column = parse_column(@fact, "sales.order_ref")

    column.name.should == :order_ref
    column.sql_name.should == :order_ref.qualify(:facts_sales).as('sales.order_ref')
    column.qualified_name.should == 'sales.order_ref'
  end

  it "returns a dimension" do
    column = parse_column(@fact, "product")

    column.name.should == :product
    column.sql_name.should == :name.qualify(:dimension_product).as('product')
    column.qualified_name.should == 'product'
  end

  it "returns a SUM of a measure" do
    column = parse_column(@fact, "sum.sales.total")

    column.name.should == :total
    column.sql_name.should == :sum[:total.qualify(:facts_sales)].as('sum.sales.total')
    column.qualified_name.should == 'sum.sales.total'
  end

  it "counts distinct rows" do
    column = parse_column(@fact, "count.sales.order_ref")

    column.sql_name.should == :count["distinct `facts_sales`.`order_ref`"].as('count.sales.order_ref')
    column.qualified_name.should == 'count.sales.order_ref'
  end

  it "counts a dimension via its original id" do
    column = parse_column(@fact, "count.product")

    column.sql_name.should == :count["distinct `dimension_product`.`original_id`"].as('count.product')
    column.qualified_name.should == 'count.product'
  end

  it "returns a column from a roleplayed dimension" do
    pending
    column = parse_column(@fact, "ship_date.year")

    column.name.should == :year
    column.sql_name.should == :year.qualify(:dimension_ship_date).as('ship_date.year')
    column.qualified_name.should == 'ship_date.year'
  end

  def parse_column(context, str)
    Chicago::ColumnParser.new.parse_column(context, str)
  end
end
