module Chicago
  module Database
    # A StarSchema Visitor which produces a hash similar to the hash
    # produced by Sequel.
    class SchemaGenerator
      attr_writer :database_strategy
      
      def initialize(database_strategy, generate_key_tables=true)
        @database_strategy = database_strategy
        @generate_key_tables = generate_key_tables
      end
      
      def generate_key_tables?
        @generate_key_tables
      end

      def traverse(schema)
        schema.tables.inject({}) {|hsh,t| hsh.merge(t.visit(self)) }
      end

      def visit_fact(fact)
        {fact.table_name => basic_table(fact)}
      end

      def visit_dimension(dimension)
        hash = {dimension.table_name => basic_table(dimension)}
        hash.merge!(key_table(dimension)) if generate_key_tables?
        hash
      end

      def visit_column(column)
        @database_strategy.column_hash(column)
      end

      alias :visit_measure :visit_column
      alias :visit_dimension_reference :visit_column

      private

      def basic_table(table)
        t = {
          :primary_key => [:id],
          :table_options => @database_strategy.table_options,
          :indexes => @database_strategy.indexes(table),
          :columns => [@database_strategy.id_column]
        }

        t[:columns] += table.columns.reject(&:calculated?).
          map {|c| c.visit(self) }
        t[:columns] << {
          :name => :_inserted_at,
          :column_type => :timestamp,
          :null => true
        }
        
        t
      end

      def key_table(dimension)
        return {} if dimension.has_predetermined_values?
        
        if dimension.original_key
          original_key_column = visit_column(dimension.original_key)
        else
          original_key_column = {
            :name => :original_id,
            :column_type => :binary,
            :null => false,
            :size => 16
          }
        end
        
        {dimension.key_table_name => {
            :primary_key => [:original_id],
            :columns => [original_key_column,
                         {:name => :dimension_id, :column_type => :integer, :unsigned => true, :null => false}]
          }
        }
      end
    end
  end
end
