module Chicago
  class Fact < StarSchemaTable
    # Returns the schema for this fact.
    def db_schema(type_converter)      
      { table_name => {
          :table_options => type_converter.dimension_table_options,
          :columns => column_definitions.map {|c| c.db_schema(type_converter) }
        }
      }
    end

    protected

    def initialize(name)
      super
      @table_name = "#{name}_facts".to_sym
    end
  end
end
