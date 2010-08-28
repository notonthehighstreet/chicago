# Requires go here
require 'sequel'
# TODO: move this back to the Sequel MySQL adapter
require 'chicago/core_ext/sequel/dataset'
require 'chicago/core_ext/array'
require 'chicago/schema/constants'
require 'chicago/data/month'

autoload :CodeStatistics, 'chicago/vendor/code_statistics.rb'

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
  autoload :RakeTasks, 'chicago/rake_tasks'
  autoload :Query,     'chicago/query'

  module Data
    autoload :PivotedDataset,         'chicago/data/pivoted_dataset'
  end

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

class Array
  include Chicago::ArrayExtensions
end
