require 'sequel/migration_builder'

module Chicago
  module Database
    # Writes Sequel migrations for the star schema
    class MigrationFileWriter
      # Creates a new migration file writer, given a Sequel::Database
      # connection and a directory. If the directory does not exist, an
      # error will be raised.
      def initialize(db, migration_directory)
        @db = db
        @migration_directory = migration_directory
      end

      # Writes the migration file necessary for all defined facts and
      # dimensions.
      def write_migration_file(schema)
        @file = nil
        type_converter = TypeConverters::DbTypeConverter.for_db(@db)
        tables = SchemaGenerator.new(type_converter).traverse(schema)

        File.open(migration_file, "w") do |fh|
          fh.write Sequel::MigrationBuilder.new(@db).generate_migration(tables)
        end
      end

      # Returns the path the migration file has been written to.
      def migration_file
        @file ||= File.join(@migration_directory, 
                            "#{Time.now.strftime("%Y%m%d%H%M%S")}_auto_migration.rb")
      end
    end
  end
end
