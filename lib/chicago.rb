# Requires go here
require 'sequel'
require 'chicago/schema/constants'

module Chicago
  # Sets the root directory for the project.
  def self.project_root=(dir)
    @project_root = dir
  end

  # Returns the root directory for the project.
  def self.project_root
    @project_root
  end

  ### Autoloads

  autoload :Definable, 'chicago/definable'

  module Schema
    autoload :Column,              'chicago/schema/column'
    autoload :StarSchemaTable,     'chicago/schema/star_schema_table'
    autoload :Dimension,           'chicago/schema/dimension'
    autoload :Fact,                'chicago/schema/fact'
    autoload :MigrationFileWriter, 'chicago/schema/migration_file_writer'
    autoload :ColumnGroupBuilder,  'chicago/schema/column_group_builder'
    autoload :TypeConverters,      'chicago/schema/type_converters'
  end

  module ETL
    autoload :TableBuilder,   'chicago/etl/table_builder.rb'
    autoload :Batch,          'chicago/etl/batch.rb'
    autoload :TaskInvocation, 'chicago/etl/task_invocation.rb'
    autoload :DatabaseSource, 'chicago/etl/database_source.rb'
  end
end
