module Chicago
  module Schema
    # Writes Sequel migrations for the star schema
    class MigrationFileWriter
      # Creates a new migration file writer, given a Sequel::Database
      # connection and a directory. If the directory does not exist, an
      # error will be raised.
      def initialize(db, migration_directory)
        @db = db
        @migration_directory = migration_directory
        @type_converter = TypeConverters::DbTypeConverter.for_db(@db)
      end

      # Writes the migration file necessary for all defined facts and dimensions.
      def write_migration_file
        @file = nil
        tables = combine_definitions(Dimension.definitions + Fact.definitions)
        File.open(migration_file, "w") do |fh|
          fh.write Sequel::MigrationBuilder.new(@db).generate_migration(tables)
        end
      end

      # Returns the path the migration file has been written to.
      def migration_file
        @file ||= File.join(@migration_directory, 
                            "#{Time.now.strftime("%Y%m%d%H%M%S")}_auto_migration.rb")
      end

      private

      def combine_definitions(definitions)
        definitions.inject({}) {|hsh, d| hsh.merge d.db_schema(@type_converter) }
      end
    end
  end
end
