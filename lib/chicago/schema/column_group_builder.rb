module Chicago
  module Schema
    TINY_INT_MAX   = 255
    SMALL_INT_MAX  = 65_535
    MEDIUM_INT_MAX = 16_777_215
    INT_MAX        = 4_294_967_295
    BIG_INT_MAX    = 18_446_744_073_709_551_615

    # A builder for DSL-style column methods to create column definitions.
    class ColumnGroupBuilder
      # Returns an Array of Columns.
      attr_reader :column_definitions
      
      def initialize(&block)
        @column_definitions = []
        instance_eval(&block) if block_given?
      end
      
      # Defines a new column.
      def column(definition)
        if definition.kind_of? Hash
          name = definition.delete(:name)
          type = definition.delete(:type)
          @column_definitions << Column.new(name, type, definition)
        else
          @column_definitions << definition
        end
      end

      # Defines a column with the type of the method name, named +name+.
      def method_missing(type, *args)
        name, rest = args
        @column_definitions << Column.new(name, type, rest || {})
      end
    end
  end
end
