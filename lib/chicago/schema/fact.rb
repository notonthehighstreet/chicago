module Chicago
  module Schema
    class Fact < StarSchemaTable
      TABLE_NAME_FORMAT = "facts_%s"

      # Returns the dimension names with which this fact table is associated.
      attr_reader :dimension_names

      # Returns the schema for this fact.
      def db_schema(type_converter)      
        {table_name => base_table(type_converter)}
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
        @degenerate_dimensions += ColumnGroupBuilder.new(&block).column_definitions
      end

      # Defines the measures for this fact.
      #
      # Measures are usually numeric values that will be aggregated.
      #
      # Within the block, use the standard column definition
      # DSL, as for defining columns on a Dimension.
      def measures(&block)
        @measures += ColumnGroupBuilder.new(:null => true, &block).column_definitions
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
        @table_name = sprintf(TABLE_NAME_FORMAT, name).to_sym
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
        idx
      end

      def dimension_key(sym)
        "#{sym}_dimension_id".to_sym
      end
    end
  end
end
