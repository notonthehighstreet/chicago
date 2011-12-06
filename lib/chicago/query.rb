require 'set'

module Chicago
  # A query interface to the star schema, similar in interface to a Sequel
  # dataset.
  #
  # A query object allows a simplified version of SQL, which leverages
  # the metadata provided by the Dimension, Fact & Column definitions
  # so that sensible defaults can be applied, and explicit joins
  # can be avoided.
  class Query
    attr_reader :dataset

    # Returns an array of Columns selected in this query.
    attr_reader :columns
    
    # Creates a new query for a Fact table.
    def self.fact(db, fact_name)
      new(db, Schema::Fact[fact_name])
    end

    # Creates a new Query object, given a database connection and a
    # schema model.
    #
    # FIXME: non-fact models will currently break.
    def initialize(db, schema_model)
      @fact = schema_model
      @dataset = db[@fact.table_name]
      @parser = ColumnParser.new
      @columns = []
      @joined_tables = Set.new
    end

    # Selects columns, generating the appropriate sql column references
    # in the built dataset.
    #
    # select may be called multiple times.
    #
    # Returns the same query object.
    def select(*cols)
      @columns += cols.map {|str| @parser.parse_column(@fact, str) }
      
      add_columns_to_dataset
      add_joins_to_dataset
      add_groups_to_dataset
      
      self
    end

    def filter(expression)
      @dataset = FilterStringParser.new(expression).apply_to(@dataset)
      self
    end
    
    # Orders the rows in this query.
    #
    # Columns is a list of strings like 'dimension.column'. Descending
    # order can be specified by prefixing the string with a '-' sign.
    def order(*columns)
      columns_to_order = columns.map do |str|
        direction = str[0..0] == '-' ? :desc : :asc
        if str[0..0] == '-'
          direction = :desc
          col_str = str[1..str.length]
        else
          direction = :asc
          col_str = str
        end

        c = @parser.parse_column(@fact, col_str)
        @columns.include?(c) ? c.qualified_name.to_sym.send(direction) : c.sql_order_name.send(direction)
      end
      
      @dataset = @dataset.order(*columns_to_order)
      self
    end

    # Limits the number of rows returned by this query.
    def limit(*args)
      @dataset = @dataset.limit(*args)
      self
    end
    
    private
    
    def add_columns_to_dataset
      @dataset = @dataset.select *(@columns.map(&:sql_name))
    end
    
    def add_joins_to_dataset
      to_join = @columns.map(&:owner).reject {|o| o == @fact || @joined_tables.include?(o) }.uniq

      @joined_tables.merge(to_join)
      
      unless to_join.empty?
        @dataset = to_join.inject(@dataset) do |dataset, d|
          dataset.join(d.table_name,
                       :id => @fact.dimension_key(d.name).qualify(@fact.table_name))
        end
      end
    end

    def add_groups_to_dataset
      cols = columns_to_group.map(&:sql_group_name).compact
      @dataset = @dataset.group(*cols)
    end

    def columns_to_group
      dimensions = @columns.select {|c| c.kind_of?(Schema::DimensionAsColumn) }.map(&:owner)
      columns.select do |c|
        c.kind_of?(Schema::DimensionAsColumn) ||
        ! dimensions.include?(c.owner)
      end
    end
  end
end
