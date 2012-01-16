module Chicago::Schema::Builders
  class ShrunkenDimensionBuilder < TableBuilder
    def initialize(schema, base_name)
      super schema
      @base_name = base_name
      @base = schema.dimensions.detect {|d| d.name == base_name }
      unless @base
        raise MissingDefinitionError.new("Base dimension #{base_name} is not defined")
      end
    end

    def build(name, &block)
      @options = {
        :columns => [],
        :identifiers => []
      }
      super Chicago::Dimension, name, &block
    end

    protected

    # Defines which columns of the base dimension are present in the
    # shrunken dimension.
    #
    # Takes an array of the column names as symbols.
    #
    # The columns must be a subset of the base dimension's columns;
    # additional names will raise a Chicago::MissingDefinitionError.
    def columns(*names)
      columns = @base.columns.select {|c| names.include?(c.name) }
      check_columns_subset_of_base_dimension names, columns
      @options[:columns] = columns
    end

    # See Chicago::Schema::Builders::DimensionBuilder#identified_by
    def identified_by(main_id, opts={:and => []})
      @options[identifiers] = [main_id] + opts[:and]
    end

    private

    def check_columns_subset_of_base_dimension(names, columns)
      if columns.size < names.size
        missing_names = names - columns.map(&:name)
        raise MissingDefinitionError.new "Columns #{missing_names.inspect} are not defined in the base dimension #{@base_name}"
      end
    end
  end
end
