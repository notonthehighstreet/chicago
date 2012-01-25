require 'set'
require 'chicago/schema/column_parser'

module Chicago  
  class Query   
    attr_reader :dataset

    # Returns an array of Columns selected in this query.
    attr_reader :columns
    
    class << self
      attr_accessor :default_schema, :default_db
    end

    # Creates a new query rooted on a Dimension table.
    def self.dimension(name)
      new(default_db, default_schema, :dimension, name)
    end

    # Creates a new query rooted on a Fact table.
    def self.fact(name)
      new(default_db, default_schema, :fact, name)
    end
    
    def initialize(db, schema, table_type, name)
      @base_table = schema.send(table_type, name)
      @dataset = db[@base_table.table_name.as(name)]
      @schema = schema
      @columns = []
      @joined_tables = Set.new
      @parser = Schema::ColumnParser.new(schema)
    end

    # Selects columns, generating the appropriate sql column references
    # in the built dataset.
    #
    # select may be called multiple times.
    #
    # Returns the same query object.
    def select(*columns)
      @columns += columns.map {|str| @parser.parse(str) }.flatten
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
        c = @parser.parse(col_str)
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
      columns_to_order = columns.map do |str|
        direction = str[0..0] == '-' ? :desc : :asc
        if str[0..0] == '-'
          direction = :desc
          col_str = str[1..str.length]
        else
          direction = :asc
          col_str = str
        end

        c = @parser.parse(col_str)
        alias_or_sql_name(c).send(direction)
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

    def alias_or_sql_name(c)
      @columns.any? {|x| x.column_alias == c.column_alias } ? c.column_alias : c.select_name
    end
    
    def add_select_columns_to_dataset
      @dataset = @dataset.select(*(@columns.map {|c| c.select_name.as(c.column_alias)}))
    end

    def add_select_joins_to_dataset(columns)
      to_join = columns.map(&:owner).uniq.reject {|t| t == @base_table || @joined_tables.include?(t) }
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
      @dataset = @dataset.group(*(@columns.map(&:group_name).compact))
    end
  end
end
