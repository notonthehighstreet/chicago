module Chicago
  module Schema
    # A builder for DSL-style column methods to create column definitions.
    class ColumnGroupBuilder
      # Returns an Array of Columns.
      attr_reader :column_definitions
      
      def initialize(owner, defaults = {}, &block)
        @owner = owner
        @defaults = defaults
        @column_definitions = []
        instance_eval(&block) if block_given?
      end
      
      # Defines a new column.
      def column(definition)
        if definition.kind_of? Hash
          name = definition.delete(:name)
          type = definition.delete(:type)
          @column_definitions << Column.new(@owner, name, type, definition)
        else
          @column_definitions << definition
        end
      end

      # Defines a column with the type of the method name, named +name+.
      def method_missing(type, *args)
        name, rest = args
        @column_definitions << Column.new(@owner, name, type, @defaults.merge(rest || {}))
      end
    end
  end
end
