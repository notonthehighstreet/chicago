module Chicago
  module Database
    class SchemaGenerator
      attr_writer :type_converter
      
      def initialize(type_converter)
        @type_converter = type_converter
      end
      
      def traverse(schema)
        schema.tables.inject({}) {|hsh,t| hsh.merge(t.visit(self)) }
      end

      def visit_fact(fact)
        {fact.table_name => basic_table(fact)}
      end

      def visit_dimension(dimension)
        table = basic_table(dimension)

        # TODO: Why shouldn't facts have etl_batch_id?
        table[:columns] << {
          :name => :etl_batch_id,
          :column_type => :integer,
          :unsigned => true
        }
        
        tables = {dimension.table_name => table}
        tables.merge!(key_table(dimension)) if dimension.original_key
        tables
      end

      def visit_column(column)
        column.to_hash.merge :column_type => @type_converter.db_type(column)
      end

      alias :visit_measure :visit_column
      alias :visit_dimension_reference :visit_column

      private

      def basic_table(table)
        t = {
          :primary_key => [:id],
          :table_options => @type_converter.table_options,
          :indexes => indexes(table),
          :columns => [{
                         :name => :id,
                         :column_type => :integer,
                         :unsigned => true
                       }]
        }
        t[:columns] += table.columns.map {|c| c.visit(self) }
        t
      end

      def key_table(dimension)
        {"keys_#{dimension.table_name}".to_sym => {
            :primary_key => [dimension.original_key.name, :dimension_id],
            :columns => [visit_column(dimension.original_key),
                         {:name => :dimension_id, :column_type => :integer, :unsigned => true, :null => false}]
          }
        }
      end
      
      def indexes(table)
        indexes = table.columns.select(&:indexed?).inject({}) do |hsh, d|
          hsh.merge("#{d.name}_idx".to_sym => {:columns => d.key_name,
                      :unique => false})
        end

        if table.natural_key
            indexes["#{table.natural_key.first}_idx".to_sym] = {
              :columns => table.natural_key.map do |name|
                table[name].key_name rescue raise MissingDefinitionError.new("Column #{name} is not defined in #{table.name}")
              end,
              :unique => true
            }
        end

        indexes
      end
    end
  end
end
