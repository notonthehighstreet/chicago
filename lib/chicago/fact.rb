module Chicago
  class Fact < StarSchemaTable
    # Returns the dimension names with which this fact table is associated.
    attr_reader :dimension_names

    # Returns the schema for this fact.
    def db_schema(type_converter)      
      { table_name => {
          :primary_key => primary_key,
          :table_options => type_converter.dimension_table_options,
          :columns => []
        }
      }
    end

    # Sets the primary key if given dimensions names, or returns the
    # primary key with no arguments.
    #
    # In general, only dimensions (real or degenerate) should be used
    # as part of the primary key. This isn't enforced at the moment,
    # but may be in the future.
    def primary_key(*dimensions)
      if dimensions.empty?
        @primary_key if defined? @primary_key
      else
        @primary_key = dimensions
      end
    end

    # Sets the dimensions with which a fact row is associated.
    def dimensions(*dimensions)
      dimensions.each do |dimension|
        @dimension_keys << ColumnDefinition.new("#{dimension}_dimension_id".to_sym, :integer, :null => false, :min => 0)
        @dimension_names << dimension
      end
    end

    # Defines the degenerate dimensions for this fact.
    #
    # Degenerate dimensions are typically ids / numbers from
    # a source system that have no associated information,
    # for example: an order number. They are used for filtering
    # and grouping facts.
    #
    # Within the block, use the standard column definition
    # DSL, as for defining columns on a Dimension.
    def degenerate_dimensions(&block)
      @degenerate_dimensions += Schema::ColumnGroupBuilder.new(&block).column_definitions
    end

    # Defines the measures for this fact.
    #
    # Measures are usually numeric values that will be aggregated.
    #
    # Within the block, use the standard column definition
    # DSL, as for defining columns on a Dimension.
    def measures(&block)
      @measures += Schema::ColumnGroupBuilder.new(&block).column_definitions
    end

    # Returns the all the column definitions for this fact.
    def column_definitions
      @dimension_keys + @degenerate_dimensions + @measures
    end

    protected

    def initialize(name)
      super
      @table_name = "#{name}_facts".to_sym
      @dimension_names = []
      @degenerate_dimensions = []
      @measures = []
      @dimension_keys = []
    end
  end
end
