module Chicago
  module ETL
    # Builds ETL tables.
    class TableBuilder
      # Creates the necessary tables for the ETL process in the given
      # database.
      def self.build(db)
        new(db).build
      end

      def initialize(db) # :nodoc:
        @db = db
      end

      def build # :nodoc:
        create_table :etl_batches do
          primary_key :id, :unsigned => true
          timestamp   :started_at
          timestamp   :finished_at, :null => true, :default => nil
        end
      end

      private

      def create_table(table, &block)
        @db.create_table(table, &block) unless @db.tables.include?(table)
      end
    end
  end
end
