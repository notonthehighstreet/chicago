module Chicago
  class DefinitionError < RuntimeError
  end

  class ColumnDefinition
    # Creates a new column definition.
    def initialize(opts)
      @opts = opts
      check_opts
    end

    def name
      @opts[:name]
    end

    def column_type
      @opts[:type]
    end

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
