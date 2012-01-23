require 'spec_helper'
require 'chicago/query'

describe Chicago::Query do
  before :all do
    @schema = Chicago::StarSchema.new

    @schema.define_dimension(:product) do
      columns do
        integer :original_id
        string :name
        string :manufacturer
        string :manufacturer_address
        string :type
        string :sku
        string :internal_code
      end

      identified_by :name
    end

    @schema.define_dimension(:customer) do
      columns do
        string :name
        string :email
      end
    end
    
    @schema.define_fact(:sales) do
      dimensions :product, :customer.as(:buyer), :customer.as(:seller)

      degenerate_dimensions do
        string :order_ref
      end

      measures do
        integer :total
        decimal :vat_rate
      end
    end

    Chicago::Query.default_schema = @schema
    Chicago::Query.default_db = TEST_DB
  end

  it "allows chained method calls with select" do
    @q = described_class.fact(:sales)
    @q.select("sales.order_ref").should be_kind_of(described_class)
  end

  it "selects the qualified columns from a fact" do
    @q = described_class.fact(:sales).select("sales.order_ref")
    @q.dataset.opts[:select].
      should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym)]
  end

  it "selects the qualified columns from a dimension" do
    @q = described_class.dimension(:product).select("product.name")
    @q.dataset.opts[:select].
      should == [:name.qualify(:product).as("product.name".to_sym)]
  end

  it "selects multiple columns from a dimension" do
    @q = described_class.dimension(:product).select("product.name", "product.type")
    @q.dataset.opts[:select].
      should == [:name.qualify(:product).as("product.name".to_sym),
                 :type.qualify(:product).as("product.type".to_sym)
                ]
  end

  it "selects multiple columns from a dimension via multiple select calls" do
    @q = described_class.new(TEST_DB, @schema, :dimension, :product)
    @q.select("product.name").select("product.type")
    @q.dataset.opts[:select].
      should == [:name.qualify(:product).as("product.name".to_sym),
                 :type.qualify(:product).as("product.type".to_sym)
                ]
  end

  it "selects a fact column and a dimension column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.order_ref", "sales.product.name")
    @q.dataset.opts[:select].
      should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym),
                 :name.qualify(:product).as("sales.product.name".to_sym)
                ]
  end

  it "selects a fact column and a roleplayed dimension column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.order_ref", "sales.seller.name")
    @q.dataset.opts[:select].
      should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym),
                 :name.qualify(:seller).as("sales.seller.name".to_sym)
                ]
  end

  it "selects an explicit sum of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.sum")
    @q.dataset.opts[:select].
      should == [:sum.sql_function(:total.qualify(:sales)).as("sales.total.sum".to_sym)]
  end

  it "selects an explicit avg of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.avg")
    @q.dataset.opts[:select].
      should == [:avg.sql_function(:total.qualify(:sales)).as("sales.total.avg".to_sym)]
  end

  it "selects an explicit maximum of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.max")
    @q.dataset.opts[:select].
      should == [:max.sql_function(:total.qualify(:sales)).as("sales.total.max".to_sym)]
  end

  it "selects an explicit minimum of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.min")
    @q.dataset.opts[:select].
      should == [:min.sql_function(:total.qualify(:sales)).as("sales.total.min".to_sym)]
  end

  it "selects an explicit sample variance of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.variance")
    @q.dataset.opts[:select].
      should == [:var_samp.sql_function(:total.qualify(:sales)).as("sales.total.variance".to_sym)]
  end

  it "selects an explicit sample standard deviation of a column" do
    @q = described_class.new(TEST_DB, @schema, :fact, :sales)
    @q.select("sales.total.stddev")
    @q.dataset.opts[:select].
      should == [:stddev_samp.sql_function(:total.qualify(:sales)).as("sales.total.stddev".to_sym)]
  end

  it "selects an explicit distinct count" do
    @q = described_class.new(TEST_DB, @schema, :dimension, :product)
    @q.select("product.type.count")
    @q.dataset.opts[:select].
      should == [:count.sql_function("distinct `product`.`type`".lit).as("product.type.count".to_sym)]
  end

  it "selects an explicit distinct count, via a dimension reference" do
    @q = described_class.new(TEST_DB, @schema, :dimension, :product)
    @q.select("sales.product.type.count")
    @q.dataset.opts[:select].
      should == [:count.sql_function("distinct `product`.`type`".lit).as("sales.product.type.count".to_sym)]
  end

  it "selects the main identifier for a bare dimension" do
    @q = described_class.new(TEST_DB, @schema, :dimension, :product)
    @q.select("sales.product")
    @q.dataset.opts[:select].
      should == [:name.qualify(:product).as("sales.product".to_sym)]
  end

  it "selects the count of a dimension" do
    @q = described_class.new(TEST_DB, @schema, :dimension, :product)
    @q.select("sales.product.count")
    @q.dataset.opts[:select].
      should == [:count.sql_function("distinct `product`.`original_id`".lit).as("sales.product.count".to_sym)]
  end

  it "allows chained method calls with select" do
    @q = described_class.fact(:sales)
    @q.select("sales.order_ref").should be_kind_of(described_class)
  end

  it "groups on a degenerate dimension column" do
    @q = described_class.fact(:sales)
    @q.select 'sales.order_ref'
    @q.dataset.opts[:group].should == ['sales.order_ref'.to_sym]
  end

  it "groups on a dimension column" do
    @q = described_class.fact(:sales)
    @q.select 'sales.product.manufacturer'
    @q.dataset.opts[:group].should == ['sales.product.manufacturer'.to_sym]
  end

  it "groups on the original key instead of a main identifier column" do
    @q = described_class.fact(:sales)
    @q.select 'sales.product.name'
    @q.dataset.opts[:group].should == [:original_id.qualify(:product)]
  end

  it "doesn't group on calculated columns" do
    @q = described_class.fact(:sales)
    @q.select 'sales.total.sum'
    @q.dataset.opts[:group].should be_nil
  end

  it "doesn't group on count columns" do
    @q = described_class.fact(:sales)
    @q.select 'sales.product.type.count, sales.product.count'
    @q.dataset.opts[:group].should be_nil
  end

  describe "joins" do
    it "doesn't join on the base table" do
      @q = described_class.fact(:sales)
      @q.select("sales.order_ref")
      @q.dataset.opts[:join].should be_nil
    end

    it "on the dimension table if selecting from the dimension" do
      described_class.fact(:sales).
        select("sales.order_ref", "sales.product.name").
        dataset.sql.
        should =~ /INNER JOIN `dimension_product` AS `product` ON \(`product`.`id` = `sales`.`product_dimension_id`\)/
    end

    it "on a roleplayed dimension table if selecting from the dimension" do
      described_class.fact(:sales).
        select("sales.order_ref", "sales.seller.name").
        dataset.sql.
        should =~ /INNER JOIN `dimension_customer` AS `seller` ON \(`seller`.`id` = `sales`.`seller_dimension_id`\)/
    end

    it "joins on multiple tables" do
      described_class.
        fact(:sales).
        select("sales.buyer.name", "sales.seller.name").
        dataset.
        opts[:join].
        map(&:table_alias).
        should == [:buyer, :seller]
    end
  end

  describe "ordering" do
    before :each do
      @q = Chicago::Query.fact(:sales)
    end

    it "can be ordered by a dimension column" do
      @q.select('sales.product.sku').order('sales.product.sku')
      @q.dataset.opts[:order].should == [:'sales.product.sku'.asc]
    end

    it "can be ordered by a column not part of the select" do
      @q.order('sales.product.sku')
      @q.dataset.opts[:order].should == [:sku.qualify(:product).asc]
    end

    it "can be ordered by a bare dimension not part of the select" do
      @q.order('sales.product')
      @q.dataset.opts[:order].should == [:name.qualify(:product).asc]
    end

    it "can be ordered in descending order" do
      @q.select('sales.product.sku').order('-sales.product.sku')
      @q.dataset.opts[:order].should == [:'sales.product.sku'.desc]
    end

    it "can be ordered in descending order for a column not part of the select" do
      @q.order('-sales.product.sku')
      @q.dataset.opts[:order].should == [:sku.qualify(:product).desc]
    end

    it "can be ordered by multiple columns" do
      @q.order('-sales.product.sku', 'sales.product.manufacturer')
      @q.dataset.opts[:order].should == [:sku.qualify(:product).desc, :manufacturer.qualify(:product).asc]
    end

    it "can be ordered on calculated columns" do
      @q.select('sales.product.sku', 'sales.total.sum')
      @q.order('sales.total.sum')
      @q.dataset.opts[:order].should == [:'sales.total.sum'.asc]
    end

    it "can be ordered on calculated columns, not in select" do
      @q.select('sales.product.sku').order('sales.total.sum')
      @q.dataset.opts[:order].should == [:sum.sql_function(:total.qualify(:sales)).asc]
    end
  end

  describe "#limit" do
    before :each do
      @q = Chicago::Query.fact(:sales)
    end

    it "returns the query" do
      @q.limit(10).should == @q
    end

    it "delegates limiting to the underlying Sequel Dataset" do
      @q.limit(10).dataset.opts[:limit].should == 10
    end
  end

  describe "#filter" do
    before :each do
      @q = Chicago::Query.fact(:sales)
    end

    it "should return the query" do
      @q.filter("sales.product.sku:123").should == @q
    end

    it "should filter based on the dimension column, not in SELECT" do
      @q.filter("sales.product.sku:123").dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => "123")
    end

    it "should filter based on the dimension column, in SELECT" do
      @q.
        select("sales.product.sku").
        filter("sales.product.sku:123").dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => "123")
    end

    it "should filter based on multiple values" do
      @q.
        select("sales.product.sku").
        filter("sales.product.sku:123,124").dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => ["123", "124"])
    end

    it "should join the filter dimension" do
      @q.filter("sales.product.sku:123,124").dataset.sql.
        should =~ /INNER JOIN `dimension_product` AS `product` ON \(`product`.`id` = `sales`.`product_dimension_id`\)/
    end

    it "should not join the base table" do
      @q.
        filter("sales.order_ref:123,124").dataset.opts[:join].should be_nil
    end
  end

  describe "#columns" do
    before :each do
      @q = Chicago::Query.fact(:sales)
    end
    
    it "returns an empty array if no columns are selected" do
      @q.columns.should be_empty
    end

    it "returns degenerate dimensions" do
      @q.select('sales.order_ref').columns.
        should == [@schema.fact(:sales)[:order_ref]]
      @q.select('sales.order_ref').columns.first.column_alias.to_s.should == 'sales.order_ref'
    end

    it "returns dimension columns" do
      @q.select("sales.product.name").columns.
        should == [@schema.dimension(:product)[:name]]
      @q.select('sales.product.name').columns.first.column_alias.to_s.should == 'sales.product.name'
    end

    it "returns measure columns" do
      column = @q.select("sales.total.sum").columns.first
      column.label.should == "Total"
      column.column_alias.to_s.should == "sales.total.sum"
    end

    it "returns the main identifier for bare dimensions" do
      column = @q.select("sales.product").columns.first
      column.label.should == "Product"
      column.column_alias.to_s.should == "sales.product"
    end

    it "returns the main identifier for bare dimensions" do
      column = @q.select("sales.product.count").columns.first
      column.label.should == "No. of Products"
      column.column_alias.to_s.should == "sales.product.count"
    end
  end
end
