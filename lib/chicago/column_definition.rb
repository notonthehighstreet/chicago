module Chicago
  # An error in the definition of dimensions or facts.
  class DefinitionError < RuntimeError
  end

  # A column in a dimension or fact record.
  class ColumnDefinition
    # Creates a new column definition.
    #
    # Requires both a :type and a :name option
    def initialize(opts)
      opts = normalize_opts(opts)
      check_opts(opts)

      @name        = opts[:name]
      @column_type = opts[:type]
      @min         = opts[:min]
      @max         = opts[:max]
      @null        = opts[:null]
      @elements    = opts[:elements]
      @default     = opts[:default]
      @opts        = opts
    end

    # Returns the name of this column.
    attr_reader :name

    # Returns the type of this column.
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

    # Returns true if a numeric column is unsigned.
    def unsigned?
      @column_type = :integer && @opts[:min] && @opts[:min] >= 0
    end

    # Returns a hash of column options for a Sequel column
    def sequel_column_options
      opts = {}
      opts[:unsigned] = unsigned? if column_type == :integer
#      opts[:default] = default

      if @opts[:size]
        opts[:size] = @opts[:size]
      elsif max && column_type == :string
        opts[:size] = max 
      elsif column_type == :money
        opts[:size] = [12,2]
      end

      opts[:null] = null?
      opts
    end

    # Returns true if both definition's attributes are equal.
    def ==(other)
      other.kind_of?(self.class) && @opts == other.instance_variable_get(:@opts)
    end

    def hash
      @opts.hash
    end

    private

    def normalize_opts(opts)
      opts = {:null => false}.merge(opts)
      if opts[:range]
        opts[:min] = opts[:range].min
        opts[:max] = opts[:range].max
        opts.delete(:range)
      end
      opts
    end

    def check_opts(opts)
      raise DefinitionError.new("A column must have a name and a type.") unless opts[:name] && opts[:type]
    end
  end
end
