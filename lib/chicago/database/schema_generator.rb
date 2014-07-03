module Chicago
  module Database
    # A StarSchema Visitor which produces a hash similar to the hash
    # produced by Sequel.
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
        {dimension.table_name => basic_table(dimension)}.
          merge!(key_table(dimension))
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
      
      def indexes(table)
        IndexGenerator.new(table).indexes
      end
    end

    class IndexGenerator
      def initialize(table)
        @table = table
      end

      def indexes
        indexes = @table.columns.select(&:indexed?).inject({}) do |hsh, d|
          hsh.merge("#{d.name}_idx".to_sym => {
                      :columns => d.database_name,
                      :unique => d.unique?})
        end
        indexes.merge!(natural_key_index) if @table.natural_key
        indexes.merge!(:_inserted_at_idx => {:columns => :_inserted_at, :unique => false})
        indexes
      end

      def natural_key_index
        {
          "#{@table.natural_key.first}_idx".to_sym => {
            :columns => natural_key_index_columns,
            :unique => true
          }
        }
      end

      def natural_key_index_columns
        @table.natural_key.map do |name|
          @table[name].database_name rescue raise MissingDefinitionError.new("Column #{name} is not defined in #{@table.name}")
        end
      end
    end
  end
end
