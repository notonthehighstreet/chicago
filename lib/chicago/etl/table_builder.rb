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
          primary_key :id, :type => :integer, :unsigned => true
          timestamp   :started_at, :null => false, :default => :current_timestamp.sql_function
          timestamp   :finished_at, :null => true, :default => nil
          enum        :state, :null => false, :elements => %w{Started Finished Error}, :default => "Started"
        end

        create_table :etl_task_invocations do
          primary_key :id, :type => :integer, :unsigned => true
          integer     :batch_id, :unsigned => true, :null => false
          enum        :stage, :null => false, :elements => %w{Extract Transform Load}
          varchar     :name, :null => false
          timestamp   :started_at, :null => false, :default => :current_timestamp.sql_function
          timestamp   :finished_at, :null => true, :default => nil
          enum        :state, :null => false, :elements => %w{Created Started Finished Error}, :default => "Created"
          smallint    :attempts, :null => false, :unsigned => true

          index [:batch_id, :stage, :name], :unique => true
        end
      end

      private

      def create_table(table, &block)
        @db.create_table(table, :engine => "innodb", &block) unless @db.tables.include?(table)
      end
    end
  end
end
