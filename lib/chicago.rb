# Requires go here
require 'sequel'
require 'sequel/extensions/inflector'

# TODO: move this back to the Sequel MySQL adapter
require 'chicago/core_ext/sequel/dataset'
require 'chicago/core_ext/array'
require 'chicago/data/month'

require 'chicago/star_schema'
require 'chicago/database/constants'
require 'chicago/database/type_converters'
require 'chicago/database/migration_file_writer'
require 'chicago/database/schema_generator'
require 'chicago/query'

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

  autoload :RakeTasks, 'chicago/rake_tasks'
  autoload :FilterStringParser, 'chicago/util/filter_string_parser'

  module Data
    autoload :PivotedDataset,         'chicago/data/pivoted_dataset'
  end

  module ETL
    autoload :TableBuilder,   'chicago/etl/table_builder.rb'
    autoload :Batch,          'chicago/etl/batch.rb'
    autoload :TaskInvocation, 'chicago/etl/task_invocation.rb'
  end
end

class Array
  include Chicago::ArrayExtensions
end
