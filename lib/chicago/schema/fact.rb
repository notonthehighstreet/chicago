module Chicago
  module Schema
    class Fact < StarSchemaTable
      TABLE_NAME_FORMAT = "facts_%s"

      # Returns the dimension names with which this fact table is associated.
      attr_reader :dimension_names

      # All measure columns for this fact.
      attr_reader :measures

      # Returns a hash of :dimension_name => Dimension
      attr_reader :dimension_definitions
      
      # Returns the schema for this fact.
      def db_schema(type_converter)      
        {table_name => base_table(type_converter)}
      end

      # Sets the dimensions with which a fact row is associated.
      def dimensions(*dimensions)
        roleplay_dimensions = dimensions.last.kind_of?(Hash) ? dimensions.pop : {}
        dimensions.each do |d|
          @dimension_definitions[d] = Dimension[d]
        end

        roleplay_dimensions.each do |name, dimension_name|
          @dimension_definitions[name] = RoleplayingDimension.new(name, Dimension[dimension_name])
        end

        dimensions += roleplay_dimensions.keys
        dimensions.each do |dimension|
          @dimension_keys << Column.new(self, dimension_key(dimension), :integer, :null => false, :min => 0)
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
        @degenerate_dimensions += ColumnGroupBuilder.new(self, &block).column_definitions
      end

      # Defines the measures for this fact.
      #
      # Measures are usually numeric values that will be aggregated.
      #
      # Within the block, use the standard column definition
      # DSL, as for defining columns on a Dimension.
      def measures(&block)
        @measures += ColumnGroupBuilder.new(self, :null => true, &block).column_definitions
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

      # Returns the dimension key for a dimension name
      #
      # TODO: move - in the wrong place
      def dimension_key(sym)
        "#{sym}_dimension_id".to_sym
      end

      protected

      def initialize(name, opts={})
        super
        @table_name = sprintf(TABLE_NAME_FORMAT, name).to_sym
        @dimension_names = []
        @degenerate_dimensions = []
        @measures = []
        @dimension_keys = []
        @dimension_definitions = {}
      end

      private

      def indexes
        idx = {}
        unless @natural_key.empty?
          dimension_names = @dimension_names.reject {|name| @natural_key.first == name }
          degenerate_dimensions = @degenerate_dimensions.reject {|d| @natural_key.first == d.name }

          key = @natural_key.map {|name| @dimension_names.include?(name) ? dimension_key(name) : name }
          idx[index_name(@natural_key.first)] = {:columns => key, :unique => true}
        end

        (dimension_names || @dimension_names).each do |name| 
          idx[index_name(name)] = {:columns => dimension_key(name), :unique => false}
        end

        (degenerate_dimensions || @degenerate_dimensions).each do |d| 
          idx[index_name(d.name)] = {:columns => d.name, :unique => false}
        end

        idx
      end
    end
  end
end
