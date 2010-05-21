module Chicago
  class DefinitionError < RuntimeError
  end

  class ColumnDefinition
    # Creates a new column definition.
    def initialize(opts)
      @opts = opts
      check_opts
    end

    # Returns the name of this column
    def name
      @opts[:name]
    end

    # Returns the type of this column.
    def column_type
      @opts[:type]
    end

    # Returns the minimum value of this column, or nil.
    def min
      @opts[:min]
    end

    def max
      @opts[:max]
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
      [:name, :type].each do |a| 
        raise DefinitionError.new("A column must have a #{a}.") unless @opts[a]
      end
    end
  end
end
