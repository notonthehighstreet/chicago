module Chicago
  # A column in a dimension or fact record.
  #
  # The column definition is used to generate the options
  # to create the column in the database schema, but also
  # to provide an abstract definition of the column for views
  # and other Data Warehouse code.
  #
  # ColumnDefinition is low-level, and you shouldn't need to
  # created one from user code - columns are generally defined
  # using the DSL on Dimension or Fact.
  class ColumnDefinition
    # Creates a new column definition.
    # 
    # name: the name of the column.
    # type: the abstract type of the column. For example, :string.
    def initialize(name, type, opts={})
      @opts = normalize_opts(opts)

      @name        = name
      @column_type = type
      @min         = @opts[:min]
      @max         = @opts[:max]
      @null        = @opts[:null]
      @elements    = @opts[:elements]
      @default     = @opts[:default]
    end

    # Returns the name of this column.
    attr_reader :name

    # Returns the type of this column. This is an abstract type,
    # not a database type (for example :string, not :varchar).
    attr_reader :column_type

    # Returns the minimum value of this column, or nil.
    attr_reader :min

    # Returns the minimum value of this column, or nil.
    attr_reader :max

    # Returns an Array of allowed elements, or nil.
    attr_reader :elements

    # Returns the default value for this column, or nil.
    attr_reader :default

    # Returns true if null values are allowed.
    def null?
      @null
    end

    # Returns true if both definition's attributes are equal.
    def ==(other)
      other.kind_of?(self.class) && 
        name == other.name && 
        column_type == other.column_type && 
        @opts == other.instance_variable_get(:@opts)
    end

    def hash #:nodoc:
      name.hash
    end

    # Returns a hash of column options for a Sequel column
    def db_schema(db)
      tc = Schema::TypeConverters::DbTypeConverter.for_db(db)

      db_schema = {
        :name => name,
        :column_type => tc.db_type(self),
        :null => null?
      }
      db_schema[:default]  = default   if default
      db_schema[:elements] = elements  if elements
      db_schema[:size]     = size      if size
      db_schema[:unsigned] = unsigned? if column_type == :integer
      db_schema
    end

    private
    
    # Returns true if a numeric column is unsigned.
    def unsigned?
      @unsigned ||= (column_type == :integer && min && min >= 0)
    end

    def size
      @size ||= if @opts[:size]
                  @opts[:size]
                elsif max && column_type == :string
                  max
                elsif column_type == :money
                  [12,2]
                end
    end

    def normalize_opts(opts)
      opts = {:null => false}.merge(opts)
      if opts[:range]
        opts[:min] = opts[:range].min
        opts[:max] = opts[:range].max
        opts.delete(:range)
      end
      opts
    end
  end
end
