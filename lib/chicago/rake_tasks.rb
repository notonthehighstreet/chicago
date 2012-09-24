require 'rake/tasklib'

module Chicago
  # Rake tasks for a Chicago project.
  #
  # To use, simply include:
  #
  #     Chicago::RakeTasks.new(db, schema)
  #
  # in your project's Rakefile.
  #
  # Provides the following tasks:
  #
  # +db:create_null_records+:: creates all the null dimension records
  #                            in db
  # +db:create_etl_tables+:: defines the tables used for ETL batches
  #                          and the like
  # +db:write_migrations+:: writes the auto migrations to a
  #                         "migrations" directory.
  #
  # @api public
  class RakeTasks < Rake::TaskLib
    def initialize(db, schema)
      @migration_dir = "migrations"
      @db = db
      @schema = schema
      define
    end

    # Defines the rake tasks.
    #
    # @api private    
    def define
      namespace :db do
        desc "Write Null dimension records"
        task :create_null_records do
          # TODO: replace this with proper logging.
          warn "Loading NULL records."
          @schema.dimensions.each {|dimension| dimension.create_null_records(@db) }
        end

        desc "Creates the etl tables"
        task :create_etl_tables do
          Chicago::ETL::TableBuilder.build(@db)
        end

        desc "Writes a migration file to change the database based on defined Facts & Dimensions"
        task :write_migrations do
          Database::MigrationFileWriter.new(@db, @migration_dir).
            write_migration_file(@schema)
        end
      end
    end
  end
end
