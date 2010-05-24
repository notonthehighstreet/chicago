module Chicago
  module Schema
    # Build relevant database tables
    class TableBuilder
      def initialize(db)
        @db = db
      end
      
      # Builds the table named +table_name+, with +columns+
      def build(table_name, columns)
        DbTableCommand.for_table(@db, table_name, columns).execute
      end
    end
  end
end
