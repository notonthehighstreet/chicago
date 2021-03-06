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
        boolean :flag
        date   :date
        integer :rating, :range => (1..10)
        string :sale, :elements => ["No", "Half Price", "Custom"]
      end

      identified_by :name
    end

    @schema.define_dimension(:customer) do
      columns do
        string :name
        string :email
        boolean :recent
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
        decimal :vat, :calculation => :sum.sql_function(:total) * :vat_rate
      end
    end

    Chicago::Query.default_db = TEST_DB
  end

  describe ".new" do
    it "raises an StandardError if the table name is missing" do
      expect {
        described_class.new(@schema, :query_type => "fact")
      }.to raise_error(StandardError)
    end

    it "raises an StandardError if the type is missing" do
      expect {
        described_class.new(@schema, :table_name => "sales")
      }.to raise_error(StandardError)
    end
  end

  describe "#table" do
    it "returns the schema table definition" do
      described_class.new(@schema, :table_name => "sales", :query_type => "fact").table.should == @schema.fact(:sales)
    end

    it "raises a MissingDefinitionError if the table is not in the schema" do
      expect {
        described_class.new(@schema, :table_name => "foo", :query_type => "fact")
      }.to raise_error Chicago::MissingDefinitionError
    end
  end

  describe "generates a dataset for a dimension that" do
    before :each do
      @q = described_class.new(@schema,
                               :table_name => "product",
                               :query_type => "dimension")
    end

    it "is a Sequel::Dataset" do
      @q.dataset.should be_kind_of(Sequel::Dataset)
    end

    it "selects a qualified column" do
      @q.select("product.name")
      @q.dataset.opts[:select].
        should == [:name.qualify(:product).as("product.name".to_sym)]
    end

    it "selects multiple qualified columns" do
      @q.select("product.name", "product.type")
      @q.dataset.opts[:select].
        should == [:name.qualify(:product).as("product.name".to_sym),
                   :type.qualify(:product).as("product.type".to_sym)
                  ]
    end

    it "selects a count" do
      @q.select({:column => "product", :op => "count"})
      @q.dataset.opts[:select].
        should == [:count.sql_function(:original_id.qualify(:product)).distinct.as("product.count".to_sym)] 
    end
  end

  describe "generates a dataset for a fact that" do
    before :each do
      @q = described_class.new(@schema,
                               :table_name => "sales",
                               :query_type => "fact")
    end

    it "is a Sequel::Dataset" do
      @q.dataset.should be_kind_of(Sequel::Dataset)
    end

    it "can be generated for a specific database" do
      dataset  = double(:dataset).as_null_object
      database = double(:database).as_null_object
      database.stub(:[]).and_return(dataset)

      @q.dataset(database).should == dataset
    end

    it "selects from the correctly aliased table" do
      @q.dataset.sql.should == TEST_DB[:facts_sales.as(:sales)].sql
    end

    it "selects a qualified column" do
      @q.select("sales.order_ref")
      @q.dataset.opts[:select].
        should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym)]
    end

    it "selects a fact column and a dimension column" do
      @q.select("sales.order_ref", "sales.product.name")
      @q.dataset.opts[:select].
        should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym),
                   :name.qualify(:product).as("sales.product.name".to_sym)
                  ]
    end

    it "selects a fact column and a roleplayed dimension column" do
      @q.select("sales.order_ref", "sales.seller.name")
      @q.dataset.opts[:select].
        should == [:order_ref.qualify(:sales).as("sales.order_ref".to_sym),
                   :name.qualify(:seller).as("sales.seller.name".to_sym)
                  ]
    end

    it "selects an explicit sum of a column" do
      @q.select({:column => "sales.total", :op => "sum"})
      @q.dataset.opts[:select].
        should == [:sum.sql_function(:total.qualify(:sales)).as("sales.total.sum".to_sym)]
    end

    it "selects an explicit avg of a column" do
      @q.select({:column => "sales.total", :op => "avg"})
      @q.dataset.opts[:select].
        should == [:avg.sql_function(:total.qualify(:sales)).as("sales.total.avg".to_sym)]
    end

    it "selects an explicit maximum of a column" do
      @q.select({:column => "sales.total", :op => "max"})
      @q.dataset.opts[:select].
        should == [:max.sql_function(:total.qualify(:sales)).as("sales.total.max".to_sym)]
    end

    it "selects an explicit minimum of a column" do
      @q.select({:column => "sales.total", :op => "min"})
      @q.dataset.opts[:select].
        should == [:min.sql_function(:total.qualify(:sales)).as("sales.total.min".to_sym)]
    end

    it "selects an explicit sample variance of a column" do
      @q.select({:column => "sales.total", :op => "variance"})
      @q.dataset.opts[:select].
        should == [:var_samp.sql_function(:total.qualify(:sales)).as("sales.total.variance".to_sym)]
    end

    it "selects an explicit sample standard deviation of a column" do
      @q.select({:column => "sales.total", :op => "stddev"})
      @q.dataset.opts[:select].
        should == [:stddev_samp.sql_function(:total.qualify(:sales)).as("sales.total.stddev".to_sym)]
    end

    it "selects an explicit sum of a column" do
      @q.select({:column => "sales.vat"})
      @q.dataset.opts[:select].
        should == [(:sum.sql_function(:total) * :vat_rate).as("sales.vat".to_sym)]
    end

    it "selects an explicit distinct count, via a dimension reference" do
      @q.select({:column => "sales.product.type", :op => "count"})
      @q.dataset.opts[:select].
        should == [:count.sql_function(:type.qualify(:product)).distinct.as("sales.product.type.count".to_sym)] 
    end

    it "selects the main identifier for a bare dimension" do
      @q.select("sales.product")
      @q.dataset.opts[:select].
        should == [:name.qualify(:product).as("sales.product".to_sym)]
    end

    it "selects the count of a dimension" do
      @q.select({:column => "sales.product", :op => "count"})
      @q.dataset.opts[:select].
        should == [:count.sql_function(:original_id.qualify(:product)).distinct.as("sales.product.count".to_sym)] 
    end

    describe "pivots columns" do
      it "raises UnimplementedError for an unbounded pivot column" do
        expect {
          @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.type"})
        }.to raise_error(Chicago::UnimplementedError)
      end

      it "via CASE, for a measure, by a boolean column" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.flag"})
        @q.dataset.opts[:select].
          should == [:sum.sql_function(Sequel.case([[{:flag.qualify(:product) => true}, :total.qualify(:sales)]], 0)).as("sales.total:sales.product.flag.0.sum".to_sym),
                     :sum.sql_function(Sequel.case([[{:flag.qualify(:product) => false}, :total.qualify(:sales)]], 0)).as("sales.total:sales.product.flag.1.sum".to_sym)
                    ]
      end

      it "that have labels of the underlying column and the value" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.flag"})
        @q.columns.first.first.label.should == ["Total", true]
        @q.columns.first.last.label.should == ["Total", false]
      end

      it "that have units of nil for averages" do
        @q.select({ :column => "sales.total",
                    :op => "avg",
                    :pivot => "sales.product.flag"})
        @q.dataset.opts[:select].
          should == [:avg.sql_function(Sequel.case([[{:flag.qualify(:product) => true}, :total.qualify(:sales)]], nil)).as("sales.total:sales.product.flag.0.avg".to_sym),
                     :avg.sql_function(Sequel.case([[{:flag.qualify(:product) => false}, :total.qualify(:sales)]], nil)).as("sales.total:sales.product.flag.1.avg".to_sym)
                    ]
      end

      it "including counts" do
        @q.select({ :column => "sales.product",
                    :op => "count",
                    :pivot => "sales.product.flag"})
        @q.dataset.opts[:select].
          should == [:count.sql_function(Sequel.case([[{:flag.qualify(:product) => true}, :original_id.qualify(:product)]], nil)).distinct.as("sales.product:sales.product.flag.0.count".to_sym),
                     :count.sql_function(Sequel.case([[{:flag.qualify(:product) => false}, :original_id.qualify(:product)]], nil)).distinct.as("sales.product:sales.product.flag.1.count".to_sym)
                    ]
      end

      it "should generate SQL pivots, via CASE, for a measure, by a bounded integer" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.rating"})
        @q.dataset.opts[:select].size.should == 10
      end

      it "should generate SQL pivots, via CASE, for a measure, by a string with elements" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.sale"})
        @q.dataset.opts[:select].size.should == 3
      end

      it "should join on the pivoted column's table if necessary" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.sale"})
        @q.dataset.opts[:join].
          should == [Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("product","id") => :product_dimension_id.qualify(:sales)),
                :inner,
                :dimension_product.as(:product))]
      end

      it "should join on the counted table when pivoting" do
        @q.select({ :column => "sales.product",
                    :op => "count",
                    :pivot => "sales.buyer.recent"})

        @q.dataset.opts[:join].
          should == [
            Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("buyer","id") => :buyer_dimension_id.qualify(:sales)),
                :inner,
                :dimension_customer.as(:buyer)),
            Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("product","id") => :product_dimension_id.qualify(:sales)),
                :inner,
                :dimension_product.as(:product))]
      end

      it "should not group on pivoted columns" do
        @q.select({ :column => "sales.total",
                    :op => "sum",
                    :pivot => "sales.product.sale"})
        @q.dataset.opts[:group].should be_nil
      end
    end

    it "groups on a degenerate dimension column" do
      @q.select 'sales.order_ref'
      @q.dataset.opts[:group].should == ['sales.order_ref'.to_sym]
    end

    it "groups on a dimension column" do
      @q.select 'sales.product.manufacturer'
      @q.dataset.opts[:group].should == ['sales.product.manufacturer'.to_sym]
    end

    it "doesn't group on calculated columns" do
      @q.select :column =>'sales.total', :op => 'sum'
      @q.dataset.opts[:group].should be_nil
    end

    it "doesn't group on count columns" do
      @q.select({:column => 'sales.product.type', :op => 'count'}, {:column => 'sales.product', :op => 'count'})
      @q.dataset.opts[:group].should be_nil
    end

    it "doesn't join on the base table" do
      @q.select("sales.order_ref")
      @q.dataset.opts[:join].should be_nil
    end

    it "joins on the dimension table if selecting from the dimension" do
      @q.select("sales.order_ref", "sales.product.name")
      @q.dataset.opts[:join].
        should == [Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("product","id") => :product_dimension_id.qualify(:sales)),
                :inner,
                :dimension_product.as(:product))]
    end

    it "joins on a roleplayed dimension table if selecting from the dimension" do
      @q.select("sales.order_ref", "sales.seller.name")
      @q.dataset.opts[:join].
        should == [Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("seller","id") => :seller_dimension_id.qualify(:sales)),
                :inner,
                :dimension_customer.as(:seller))]
    end

    it "joins when counting dimensions" do
      @q.select({:column => "sales.product", :op => "count"})
      @q.dataset.opts[:join].
        should == [Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("product","id") => :product_dimension_id.qualify(:sales)),
                :inner,
                :dimension_product.as(:product))]
    end

    it "joins on multiple tables" do
      @q.select("sales.buyer.name", "sales.seller.name")
      @q.dataset.opts[:join].map(&:table_alias).
        should == [:buyer, :seller]
    end

    it "can be ordered by a dimension column" do
      @q.select('sales.product.sku').order('sales.product.sku')
      @q.dataset.opts[:order].should == [:'sales.product.sku'.asc]
    end

    it "can be ordered in descending order" do
      @q.select('sales.product.sku').order({:column => 'sales.product.sku', :ascending => false})
      @q.dataset.opts[:order].should == [:'sales.product.sku'.desc]
    end

    it "can be ordered in descending order for a column not part of the select" do
      @q.select('sales.product.sku').order({:column => 'sales.product.sku', :ascending => false})
      @q.dataset.opts[:order].should == [:"sales.product.sku".desc]
    end

    it "can be ordered by multiple columns" do
      @q.select('sales.product.sku', 'sales.product.manufacturer').order({:column => 'sales.product.sku', :ascending => false}, 'sales.product.manufacturer')
      @q.dataset.opts[:order].should == [:"sales.product.sku".desc, :"sales.product.manufacturer".asc]
    end

    it "can be ordered on calculated columns" do
      @q.select('sales.product.sku', 'sales.total.sum')
      @q.order('sales.total.sum')
      @q.dataset.opts[:order].should == [:'sales.total.sum'.asc]
    end

    it "#filter returns the query" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :eq}).should == @q
    end

    it "filters based on the dimension column, not in SELECT" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :eq}).dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => "123")
    end

    it "filters based on the dimension column, in SELECT" do
      @q.
        select("sales.product.sku").
        filter({:column => "sales.product.sku", :value => "123", :op => :eq}).dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => "123")
    end

    it "filters based on multiple values" do
      @q.
        select("sales.product.sku").
        filter({:column => "sales.product.sku", :value => ["123", "124"], :op => :eq}).dataset.opts[:where].
        should == Sequel::SQL::BooleanExpression.from_value_pairs(:sku.qualify(:product) => ["123", "124"])
    end

    it "joins a filter dimension" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :eq}).dataset.opts[:join].
        should == [Sequel::SQL::JoinOnClause.new(
                Sequel.expr(Sequel.qualify("product","id") => :product_dimension_id.qualify(:sales)),
                :inner,
                :dimension_product.as(:product))]
    end

    it "can filter based on greater than" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :gt}).dataset.opts[:where].
        should == Sequel.expr(:rating.qualify(:product) > 2)
    end

    it "can filter based on greater than or equal" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :gte}).dataset.opts[:where].
        should == Sequel.expr(:rating.qualify(:product) >= 2)
    end

    it "can filter based on less than" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :lt}).dataset.opts[:where].
        should == Sequel.expr(:rating.qualify(:product) < 2)
    end

    it "can filter based on less than or equal" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :lte}).dataset.opts[:where].
        should == Sequel.expr(:rating.qualify(:product) <= 2)
    end

    it "can filter multiple integers" do
      @q.filter({:column => "sales.product.rating", :value => ["1", "2"], :op => :eq}).dataset.opts[:where].
        should == Sequel.expr(:rating.qualify(:product) => [1, 2])
    end

    it "can filter based on not equal" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :ne}).dataset.opts[:where].
        should == Sequel.~(Sequel.expr(:rating.qualify(:product) => 2))
    end

    it "can filter based on 2 comparisons" do
      @q.filter({:column => "sales.product.rating", :value => "2", :op => :gte}, {:column => "sales.product.rating", :value => "7", :op => :lt}).dataset.opts[:where].
        should == Sequel.&(Sequel.expr(:rating.qualify(:product) >= 2),Sequel.expr(:rating.qualify(:product) < 7))
    end

    it "can filter dates" do
      @q.filter({:column => "sales.product.date", :value => "01/02/12", :op => :eq}).dataset.opts[:where].
        should == Sequel.expr(:date.qualify(:product) => Date.new(year=2012,month=2,day=1))
    end

    it "can filter based on starts with" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :sw}).dataset.opts[:where].
        should == Sequel.ilike(:sku.qualify(:product), "123%")
    end

    it "can filter based on 'starts with' with multiple values" do
      @q.filter({:column => "sales.product.sku", :value => ["123","AB"], :op => :sw}).dataset.opts[:where].
        should == Sequel.|(Sequel.ilike(:sku.qualify(:product), "123%"), Sequel.ilike(:sku.qualify(:product), "AB%"))

    end

    it "can filter based on not starts with" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :nsw}).dataset.opts[:where].
        should == Sequel.~(Sequel.ilike(:sku.qualify(:product), "123%"))
    end

    it "can filter based on 'not starts with' with multiple values" do
      @q.filter({:column => "sales.product.sku", :value => ["123","AB"], :op => :nsw}).dataset.opts[:where].
        should == Sequel.&(Sequel.~(Sequel.ilike(:sku.qualify(:product), "123%")), Sequel.~(Sequel.ilike(:sku.qualify(:product), "AB%")))
    end

    it "can filter based on contains" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :con}).dataset.opts[:where].
        should == Sequel.ilike(:sku.qualify(:product), "%123%")
    end

    it "can filter based on not contains" do
      @q.filter({:column => "sales.product.sku", :value => "123", :op => :ncon}).dataset.opts[:where].
        should == Sequel.~(Sequel.ilike(:sku.qualify(:product), "%123%"))
    end

    it "can filter based on multiple contains" do
      @q.filter({:column => "sales.product.sku", :value => ["123", "AB", "foo"], :op => :con}).dataset.opts[:where].
        should == Sequel.|(Sequel.ilike(:sku.qualify(:product), "%123%"), Sequel.ilike(:sku.qualify(:product), "%AB%"), Sequel.ilike(:sku.qualify(:product), "%foo%"))
    end

    it "can filter based on multiple not contains" do
      @q.filter({:column => "sales.product.sku", :value => ["123", "AB", "foo"], :op => :ncon}).dataset.opts[:where].
        should == Sequel.&(Sequel.~(Sequel.ilike(:sku.qualify(:product), "%123%")), Sequel.~(Sequel.ilike(:sku.qualify(:product), "%AB%")), Sequel.~(Sequel.ilike(:sku.qualify(:product), "%foo%")))
    end

    it "does not join the base table when filtering" do
      @q.
        filter({:column => "sales.order_ref", :value => "123", :op => :eq}).dataset.opts[:join].should be_nil
    end

    it "filters in the having clause when a calculated column is filtered" do
      @q.filter({:column => {:column => "sales.total", :op => "sum"}, :value => 2, :op => :eq}).dataset.opts[:having].
        should == Sequel.expr(:sum.sql_function(:total.qualify(:sales)) => 2)
    end

    it "filters in the having clause when a virtual calculated column is filtered" do
      @q.filter({:column => "sales.vat", :value => 2, :op => :gte}).dataset.opts[:having].
        should == Sequel.expr(Sequel.*(:sum.sql_function(:total),:vat_rate) >= 2)
    end

    describe "#columns" do
      it "returns an empty array if no columns are selected" do
        @q.columns.should be_empty
      end

      it "returns degenerate dimensions" do
        @q.select('sales.order_ref').columns.
          should == [[@schema.fact(:sales)[:order_ref]]]
        @q.select('sales.order_ref').columns.first.first.column_alias.to_s.should == 'sales.order_ref'
      end

      it "returns dimension columns" do
        @q.select("sales.product.name").columns.
          should == [[@schema.dimension(:product)[:name]]]
        @q.select('sales.product.name').columns.first.first.column_alias.to_s.should == 'sales.product.name'
      end

      it "returns measure columns" do
        column = @q.select({:column => "sales.total", :op => "sum"}).columns.first.first
        column.label.should == "Total"
        column.column_alias.to_s.should == "sales.total.sum"
      end

      it "returns the main identifier for bare dimensions" do
        column = @q.select("sales.product").columns.first.first
        column.label.should == "Product"
        column.column_alias.to_s.should == "sales.product"
      end

      it "returns the main identifier for bare dimensions" do
        column = @q.select({:column => "sales.product", :op => "count"}).columns.first.first
        column.label.should == "No. of Products"
        column.column_alias.to_s.should == "sales.product.count"
      end
    end
  end
end
