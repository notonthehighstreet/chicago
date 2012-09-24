# Requires go here
require 'chronic'
require 'sequel'
require 'sequel/extensions/inflector'

# TODO: move this back to the Sequel MySQL adapter
require 'chicago/core_ext/sequel/dataset'
require 'chicago/core_ext/sequel/sql'

require 'chicago/core_ext/hash'
require 'chicago/data/month'

require 'chicago/star_schema'
require 'chicago/database/constants'
require 'chicago/database/type_converters'
require 'chicago/database/migration_file_writer'
require 'chicago/database/schema_generator'
require 'chicago/query'

module Chicago
  class << self
    # The root directory for the project.
    attr_accessor :project_root
  end
  
  # @api private
  module Database
  end
  
  ### Autoloads
  autoload :RakeTasks, 'chicago/rake_tasks'

  module ETL
    autoload :TableBuilder,   'chicago/etl/table_builder.rb'
    autoload :Batch,          'chicago/etl/batch.rb'
    autoload :TaskInvocation, 'chicago/etl/task_invocation.rb'
  end
end
