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
    def initialize(schema, options)
      @schema = schema
      @base_migration_dir = options[:migration_directory] ||= "migrations"
      @staging_db = options[:staging_db] or raise ArgumentError.new("staging_db option must be provided.")
      @presentation_db = options[:presentation_db]

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
          @schema.dimensions.each do |dimension| 
            dimension.create_null_records(@db) 
          end
        end

        desc "Writes a migration file to change the database based on defined Facts & Dimensions"
        task :write_migrations do
          writer = Database::MigrationFileWriter.new
          writer.write_migration_file(@staging_db, @schema,
                                      staging_directory)

          if @presentation_db
            writer.write_migration_file(@presentation_db, @schema, 
                                        presentation_directory, false)
          end
        end
      end
    end

    private

    def staging_directory
      File.join(@base_migration_dir, "staging")
    end

    def presentation_directory
      File.join(@base_migration_dir, "presentation")
    end
  end
end
