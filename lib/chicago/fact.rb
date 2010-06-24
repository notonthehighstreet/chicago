module Chicago
  class Fact < StarSchemaTable
    # Returns the dimension names with which this fact table is associated.
    attr_reader :dimension_names

    # Returns the schema for this fact.
    def db_schema(type_converter)      
      { table_name => {
          :primary_key => primary_key,
          :table_options => type_converter.table_options,
          :indexes => indexes,
          :columns => column_definitions.map {|c| c.db_schema(type_converter) }
        }
      }
    end

    # Sets the primary key if given dimensions names, or returns the
    # primary key columns if called with no arguments.
    #
    # In general, only dimensions (real or degenerate) should be used
    # as part of the primary key. This isn't enforced at the moment,
    # but may be in the future.
    def primary_key(*dimensions)
      if dimensions.empty?
        @primary_key.call if defined? @primary_key
      else
        @primary_key = lambda do
          keys = dimensions.map {|sym| @dimension_names.include?(sym) ? dimension_key(sym) : sym }
          keys.size == 1 ? keys.first : keys
        end
      end
    end

    # Sets the dimensions with which a fact row is associated.
    def dimensions(*dimensions)
      dimensions += dimensions.pop.keys if dimensions.last.kind_of? Hash
      dimensions.each do |dimension|
        @dimension_keys << Column.new(dimension_key(dimension), :integer, :null => false, :min => 0)
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
      @measures += Schema::ColumnGroupBuilder.new(:null => true, &block).column_definitions
    end

    # Returns the all the column definitions for this fact.
    def column_definitions
      @dimension_keys + @degenerate_dimensions + @measures
    end

    # A Factless Fact table has no measures - it used only to express a
    # relationship between a set of dimensions.
    def factless?
      @measures.empty?
    end

    protected

    def initialize(name, opts={})
      super
      @table_name = "#{name}_facts".to_sym
      @dimension_names = []
      @degenerate_dimensions = []
      @measures = []
      @dimension_keys = []
    end

    private

    def indexes
      idx = {}
      @dimension_names.each {|name| idx[index_name(name)] = {:columns => dimension_key(name)} }
      @degenerate_dimensions.each {|d| idx[index_name(d.name)] = {:columns => d.name} }

      if primary_key
        first_pk_column = primary_key.kind_of?(Array) ? primary_key.first : primary_key
        idx.delete(index_name(first_pk_column.to_s.sub(/_dimension_id/,'').to_sym))
      end

      idx
    end

    def index_name(name)
      "#{name}_idx".to_sym
    end

    def dimension_key(sym)
      "#{sym}_dimension_id".to_sym
    end
  end
end
