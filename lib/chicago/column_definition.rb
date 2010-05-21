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
      @name        = opts[:name]
      @column_type = opts[:type]
      @min         = opts[:min]
      @max         = opts[:max]
      @opts        = opts
      check_opts
    end

    # Column definitions are equal if their attributes are equal.
    def ==(other)
      other.kind_of?(self.class) && @opts == other.instance_variable_get(:@opts)
    end

    def hash
      @opts.hash
    end

    private

    def check_opts
      raise DefinitionError.new("A column must have a name.") unless @name
      raise DefinitionError.new("A column must have a type.") unless @column_type
    end
  end
end
