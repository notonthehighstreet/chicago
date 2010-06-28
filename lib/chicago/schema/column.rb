module Chicago
  module Schema
  # A column in a dimension or fact record.
  #
  # The column definition is used to generate the options
  # to create the column in the database schema, but also
  # to provide an abstract definition of the column for views
  # and other Data Warehouse code.
  #
  # You shouldn't need to create a Column manually - they
  # are generally defined using the DSL on Dimension or Fact.
  class Column
    # Creates a new column definition.
    # 
    # name: the name of the column.
    # type: the abstract type of the column. For example, :string.
    #
    # Options:
    #
    # min:      the minimum length/number of this column.
    # max:      the maximum length/number of this column.
    # range:    any object with a min & max method - overrides min/max (above).
    # null:     whether this column can be null. False by default.
    # elements: the allowed values this column can take.
    # default:  the default value for this column. 
    def initialize(name, type, opts={})
      @opts = normalize_opts(type, opts)

      @name        = name
      @column_type = type
      @min         = @opts[:min]
      @max         = @opts[:max]
      @null        = @opts[:null]
      @elements    = @opts[:elements]
      @default     = @opts[:default]
      @descriptive = !! @opts[:descriptive]
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

    # Returns true if this column is just informational, and is not
    # intended to be used as a filter.
    def descriptive?
      @descriptive
    end

    # Returns true if both definition's attributes are equal.
    def ==(other)
      other.kind_of?(self.class) && 
        name == other.name && 
        column_type == other.column_type && 
        @opts == other.instance_variable_get(:@opts)
    end

    # Returns a hash of column options for a Sequel column
    def db_schema(type_converter)
      db_schema = {
        :name => name,
        :column_type => type_converter.db_type(self),
        :null => null?
      }
      db_schema[:default]  = default   if default || column_type == :timestamp
      db_schema[:elements] = elements  if elements
      db_schema[:size]     = size      if size
      db_schema[:unsigned] = !! unsigned? if numeric?
      db_schema
    end

    # Returns true if this column stores a numeric value.
    def numeric?
      @numeric ||= [:integer, :money, :percent, :decimal, :float].include?(column_type)
    end

    def hash #:nodoc:
      name.hash
    end

    private
    
    def unsigned?
      return @unsigned if defined? @unsigned      
      default_unsigned = column_type == :percent || column_type == :money
      @unsigned = min ? min >= 0 : default_unsigned
    end

    def size
      @size ||= if @opts[:size]
                  @opts[:size]
                elsif max && column_type == :string
                  max
                elsif column_type == :money
                  [12,2]
                elsif column_type == :percent
                  [6,3]
                end
    end

    def normalize_opts(type, opts)
      opts = {:null => default_null(type), :min => default_min(type)}.merge(opts)
      if opts[:range]
        opts[:min] = opts[:range].min
        opts[:max] = opts[:range].max
        opts.delete(:range)
      end
      opts
    end

    def default_null(type)
      [:date, :timestamp, :datetime].include?(type)
    end

    def default_min(type)
      0 if type == :money
    end
  end
end
end
