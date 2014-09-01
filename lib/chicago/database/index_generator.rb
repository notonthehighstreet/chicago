module Chicago
  module Database
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
