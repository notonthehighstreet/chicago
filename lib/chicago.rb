# Requires go here
require 'sequel'
require 'chicago/definable'
require 'chicago/schema/constants'
require 'chicago/schema/column'
require 'chicago/schema/star_schema_table'
require 'chicago/schema/dimension'
require 'chicago/schema/fact'

module Chicago
  # Sets the root directory for the project.
  def self.project_root=(dir)
    @project_root = dir
  end

  # Returns the root directory for the project.
  def self.project_root
    @project_root
  end
  
  module Schema
    autoload :MigrationFileWriter, 'chicago/schema/migration_file_writer'
    autoload :ColumnGroupBuilder,  'chicago/schema/column_group_builder'
    autoload :TypeConverters,      'chicago/schema/type_converters'
  end

  module ETL
    autoload :TableBuilder,   "chicago/etl/table_builder.rb"
    autoload :Batch,          "chicago/etl/batch.rb"
    autoload :TaskInvocation, "chicago/etl/task_invocation.rb"
    autoload :TableSource,    "chicago/etl/table_source.rb"
  end
end
