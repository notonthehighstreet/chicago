module Chicago
  class TableBuilder

    def initialize(db, migration_directory)
      @db = db
      @migration_directory = migration_directory
      @type_converter = Schema::TypeConverter.for_db(@db)
    end

    def build_migration_file
      tables = (Dimension.definitions + Fact.definitions).inject({}) do |hsh, d|
        hsh.merge d.db_schema(@type_converter)
      end
      File.open(migration_file, "w") {|fh|
        fh.write Sequel::MigrationBuilder.new(@db).generate_migration(tables)
      }
    end

    def migration_file
    end
  end
end
