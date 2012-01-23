require 'set'

module Chicago
  class ColumnDecorator
    instance_methods.each do |m|
      undef_method m unless m =~ /(^__|^send$|^object_id$)/
    end

    def initialize(column)
      @column = column
    end

    def method_missing(*args, &block)
      @column.send(*args, &block)
    end
  end
  
  class QualifiedColumn < ColumnDecorator
    def initialize(owner, column, column_alias)
      super column
      @owner = owner
      @column_alias = column_alias

      if column.kind_of?(Chicago::Schema::Dimension)
        @select_name = @column.main_identifier.qualify(@column.name)
      else
        @select_name = @column.name.qualify(@owner.name)
      end
      
      if owner.kind_of?(Chicago::Schema::Dimension) && owner.identifiable? && owner.identifiers.include?(column.name)
        @group_name = owner.original_key.name.qualify(owner.name)
      else
        @group_name = column_alias
      end
    end
    
    attr_reader :owner, :select_name, :column_alias, :group_name
  end

  class SqlSimpleAggregateColumn < ColumnDecorator
    def initialize(column, operation)
      super column
      @operation = operation
      normalize_operation
    end
    
    def select_name
      @operation.sql_function(@column.select_name)
    end

    def group_name
      nil
    end

    private

    def normalize_operation
      @operation = :var_samp if @operation == :variance
      @operation = :stddev_samp if @operation == :stddev     
    end
  end

  class CountColumn < ColumnDecorator
    def select_name
      if @column.kind_of?(Schema::Dimension)
        :count.sql_function("distinct `#{@column.owner.name}`.`#{@column.original_key.name}`".lit)
      else
        :count.sql_function("distinct `#{@column.owner.name}`.`#{@column.select_name.column}`".lit)
      end
    end

    def label
      "No. of #{@column.label.pluralize}"
    end
    
    def group_name
      nil
    end
  end
  
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
    end

    # Selects columns, generating the appropriate sql column references
    # in the built dataset.
    #
    # select may be called multiple times.
    #
    # Returns the same query object.
    def select(*columns)
      @columns += columns.map {|str| parse_column(str) }
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
        c = parse_column(col_str)
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

        c = parse_column(col_str)
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
    
    def parse_column(str)
      parts = str.split('.').map(&:to_sym)
      root = parts.shift
      table = @schema.fact(root) || @schema.dimension(root)

      col = table[parts.shift]

      if col.kind_of?(Chicago::Schema::Dimension)
        table = col
        new_column_name = parts.shift
        if new_column_name.nil?
          col = table
        elsif new_column_name == :count
          col = table
          parts.unshift :count
        else
          col = table[new_column_name]
        end
      end

      return_column = QualifiedColumn.new(table, col, str.to_sym)

      unless parts.empty?
        operation = parts.shift
        if operation == :count
          return_column = CountColumn.new(return_column)
        else
          return_column = SqlSimpleAggregateColumn.new(return_column, operation)
        end
      end

      return_column
    end    
  end
end
