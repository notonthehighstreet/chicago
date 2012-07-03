module Chicago
  module ETL
    # Generates filter conditions for incremental loads based on an
    # etl batch ID.
    class BatchedDatasetFilter
      attr_reader :filter_column

      def initialize(db)
        @db = db
        @filter_column = :etl_batch_id
      end

      # Returns an array of condition hashes, for each of the tables that
      # is filterable using the etl_batch_id column.
      def conditions(tables, etl_batch)
        tables.
          select {|table| filterable?(table) }.
          map {|table| {filter_column.qualify(table) => etl_batch.id} }
      end

      # Returns true if the table has an etl batch id column, and so can
      # be filtered in an incremental ETL load.
      def filterable?(table)
        @db.schema(table).map(&:first).include?(filter_column)
      end
    end
  end
end
