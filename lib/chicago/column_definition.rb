module Chicago
  # An error in the definition of dimensions or facts.
  class DefinitionError < RuntimeError
  end

  # A column in a dimension or fact record.
  class ColumnDefinition
    # Returns the name of this column
    attr_reader :name

    # Returns the type of this column.
    attr_reader :column_type

    # Returns the minimum value of this column, or nil.
    attr_reader :min

    # Returns the minimum value of this column, or nil.
    attr_reader :max

    # Creates a new column definition.
    #
    # Requires both a :type and a :name option
    def initialize(opts)
      normalize_opts(opts)
      check_opts(opts)

      @name        = opts[:name]
      @column_type = opts[:type]
      @min         = opts[:min]
      @max         = opts[:max]
      @opts        = opts
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
      if opts[:range]
        opts[:min] = opts[:range].min
        opts[:max] = opts[:range].max
        opts.delete(:range)
      end
    end

    def check_opts(opts)
      raise DefinitionError.new("A column must have a name and a type.") unless opts[:name] && opts[:type]
    end
  end
end
