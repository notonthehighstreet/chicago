require 'set'
require 'chicago/schema/column_parser'

module Chicago  
  class Query   
    # Returns the dataset built by this query.
    attr_reader :dataset

    # Returns an array of Columns selected in this query.
    attr_reader :columns
    
    class << self
      # Sets the default Chicago::StarSchema used by queries.
      attr_accessor :default_schema

      # Sets the default Sequel::Database used by queries.
      attr_accessor :default_db

      # Sets the column parser class to be used.
      #
      # By default Schema::ColumnParser
      attr_accessor :column_parser
    end
    self.column_parser = Schema::ColumnParser
    
    # Creates a new query rooted on a Dimension table.
    def self.dimension(name)
      new(default_db, default_schema, :dimension, name)
    end

    # Creates a new query rooted on a Fact table.
    def self.fact(name)
      new(default_db, default_schema, :fact, name)
    end

    # Creates a new Query, given a Sequel::Database, a
    # Chicago::StarSchema, either :fact or :dimension and a table
    # name.
    #
    # If you only have one schema in your application, use the fact
    # and dimension factory methods instead.
    def initialize(db, schema, table_type, name)
      @base_table = schema.send(table_type, name)
      @dataset = db[@base_table.table_name.as(name)]
      @schema = schema
      @columns = []
      @joined_tables = Set.new
      @parser = self.class.column_parser.new(schema)
    end

    # Selects columns, generating the appropriate sql column references
    # in the built dataset.
    #
    # select may be called multiple times.
    #
    # Returns the same query object.
    def select(*columns)
      @columns += columns.map {|str| @parser.parse(str) }
      add_select_columns_to_dataset
      add_select_joins_to_dataset(@columns)
      add_group_to_dataset
      self
    end

    # Filters results, generating the appropriate WHERE clause and
    # adding joins where appropriate.
    #
    # filter may be called multiple times.
    #
    # Returns the same query object.
    def filter(*filters)
      filter_columns = []
      
      filter_attributes = filters.inject({}) do |filters, filter|
        col_str, value = filter.split(":")
        value = value.split(",")
        value = value.size == 1 ? value.first : value
        c = @parser.parse(col_str).first
        filter_columns << c
        filters.merge(c.select_name => value)
      end
      add_select_joins_to_dataset(filter_columns)
      @dataset = @dataset.filter(filter_attributes)
      self
    end
    
    # Orders the rows in this query.
    #
    # Columns is a list of strings like 'dimension.column'. Descending
    # order can be specified by prefixing the string with a '-' sign.
    def order(*columns)
      columns_to_order = columns.flatten.map do |str|
        direction = str[0..0] == '-' ? :desc : :asc
        if str[0..0] == '-'
          direction = :desc
          col_str = str[1..str.length]
        else
          direction = :asc
          col_str = str
        end

        c = @parser.parse(col_str).first
        alias_or_sql_name(c).send(direction)
      end
      
      @dataset = @dataset.order(*columns_to_order)
      self
    end

    # Limits the number of rows returned by this query.
    #
    # See Sequel::Dataset#limit
    def limit(*args)
      @dataset = @dataset.limit(*args)
      self
    end
    
    private

    def alias_or_sql_name(c)
      @columns.flatten.any? {|x| x.column_alias == c.column_alias } ? c.column_alias : c.select_name
    end
    
    def add_select_columns_to_dataset
      @dataset = @dataset.select(*(@columns.flatten.map {|c| c.select_name.as(c.column_alias)}))
    end

    def add_select_joins_to_dataset(columns)
      to_join = columns.flatten.map(&:owner).flatten.uniq.reject {|t| t == @base_table || @joined_tables.include?(t) }
      add_joins_to_dataset(to_join)
    end
    
    def add_joins_to_dataset(to_join)
      @joined_tables.merge(to_join)
      
      unless to_join.empty?
        @dataset = to_join.inject(@dataset) do |dataset, t|
          dataset.join(t.table_name.as(t.name), :id => t.key_name.qualify(@base_table.name))
        end
      end
    end
    
    def add_group_to_dataset
      @dataset = @dataset.group(*(@columns.flatten.map(&:group_name).compact))
    end
  end
end
