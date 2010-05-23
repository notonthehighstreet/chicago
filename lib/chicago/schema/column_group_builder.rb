module Chicago
  module Schema
    # A builder for DSL-style column methods to create column definitions.
    class ColumnGroupBuilder
      # Returns an Array of ColumnDefinitions.
      attr_reader :column_definitions
      
      def initialize(&block)
        @column_definitions = []
        instance_eval(&block) if block_given?
      end
      
      # Defines a new column.
      def column(definition)
        if definition.kind_of? Hash
          @column_definitions << ColumnDefinition.new(definition)
        else
          @column_definitions << definition
        end
      end

      # Defines a column with the type of the method name, named +name+.
      def method_missing(type, *args)
        name, rest = args
        column(:type => type, :name => name)
      end
    end
  end
end
