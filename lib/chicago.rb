# Requires go here
require 'sequel'
require 'sequel/migration_builder'
require 'chicago/schema/constants'
require 'chicago/schema/column'
require 'chicago/schema/star_schema_table'
require 'chicago/schema/dimension'
require 'chicago/schema/fact'
require 'chicago/schema/type_converters'

module Chicago
  module Schema
    autoload :MigrationFileWriter, 'chicago/schema/migration_file_writer'
    autoload :ColumnGroupBuilder,  'chicago/schema/column_group_builder'
  end

  module ETL
    autoload :TableBuilder, "chicago/etl/table_builder.rb"
  end
end
