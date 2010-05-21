module Chicago
  class DefinitionError < RuntimeError
  end

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
    def initialize(opts)
      normalize_opts(opts)

      @name        = opts[:name]
      @column_type = opts[:type]
      @min         = opts[:min]
      @max         = opts[:max]
      @opts        = opts
    end

    # Column definitions are equal if their attributes are equal.
    def ==(other)
      other.kind_of?(self.class) && @opts == other.instance_variable_get(:@opts)
    end

    def hash
      @opts.hash
    end

    private

    def normalize_opts(opts)
      raise DefinitionError.new("A column must have a name.") unless opts[:name]
      raise DefinitionError.new("A column must have a type.") unless opts[:type]

      if opts[:range]
        opts[:min] = opts[:range].min
        opts[:max] = opts[:range].max
        opts.delete(:range)
      end
    end
  end
end
