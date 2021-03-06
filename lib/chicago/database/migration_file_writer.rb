require 'sequel/migration_builder'

module Chicago
  module Database
    # Writes Sequel migrations for the star schema
    class MigrationFileWriter
      # Writes the migration file necessary for all defined facts and
      # dimensions.
      def write_migration_file(db, schema, directory, generate_key_tables=true)
        schema_strategy = ConcreteSchemaStrategy.for_db(db)
        tables = SchemaGenerator.new(schema_strategy, generate_key_tables).traverse(schema)

        File.open(migration_file(directory), "w") do |fh|
          fh.write Sequel::MigrationBuilder.new(db, schema_strategy.migration_options).
            generate_migration(tables)
        end
      end

      # Returns the path the migration file has been written to.
      def migration_file(directory)
        File.join(directory, migration_file_name)
      end

      private

      def migration_file_name
        @migration_file_name ||= "#{Time.now.strftime("%Y%m%d%H%M%S")}_auto_migration.rb"
      end
    end
  end
end
