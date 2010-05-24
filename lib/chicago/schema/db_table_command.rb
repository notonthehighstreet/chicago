module Chicago
  module Schema
    # A command to alter or create a table to bring it in line with a
    # set of column definitions.
    #
    # This is an abstract class and should not be instantiated.
    class DbTableCommand
      # Returns a DbTableCommand subclass appropriate for modifying or creating tables.
      def self.for_table(db, table_name, columns)
        subclass = db.table_exists?(table_name) ? AlterTableCommand : CreateTableCommand
        subclass.new(db, table_name, columns)
      end

      def initialize(db, table_name, columns)
        @db = db
        @table_name = table_name
        @columns = columns
        @type_converter = TypeConverters::DbTypeConverter.for_db(@db)
        build_generator
      end

      # Execute the command. Overriden in subclasses.
      def create_or_modify_table ; end
      
      # Returns the associated Sequel Generator used to create DDL statements. Overriden in subclasses.
      def generator ; end

      protected

      # Build the Sequel::Schema::*Generator - Overriden in subclasses.
      def build_generator ; end
    end


    # A command to create a new table.
    #
    # This shouldn't be created directly - use DbTableCommand.for_table
    class CreateTableCommand < DbTableCommand #:nodoc:
      def generator
        @generator ||= Sequel::Schema::Generator.new(@db)
      end

      def create_or_modify_table
        @db.create_table(@table_name, :generator => generator)      
      end

      protected

      def build_generator
        @columns.each do |column|
          generator.column(column.name, @type_converter.db_type(column), column.sequel_column_options)
        end
      end
    end


    # A command to alter a prexisting table.
    #
    # This shouldn't be created directly - use DbTableCommand.for_table
    class AlterTableCommand < DbTableCommand #:nodoc:
      def generator
        @generator ||= Sequel::Schema::AlterTableGenerator.new(@db)
      end

      def create_or_modify_table
        @db.alter_table(@table_name, generator) unless generator.operations.empty?
        @db.alter_table(@table_name, null_generator) unless null_generator.operations.empty?
      end

      protected

      def null_generator
        @db.schema(@table_name, :reload => true)
        @null_generator ||= Sequel::Schema::AlterTableGenerator.new(@db)
      end

      def build_generator
        current_columns, new_columns = @columns.partition {|c| @db[@table_name].columns.include?(c.name) }
        create_new_columns(generator, new_columns)
        modify_existing_columns(generator, current_columns)
      end

      private

      def create_new_columns(generator, new_columns)
        new_columns.each do |column|
          generator.add_column(column.name, @type_converter.db_type(column), column.sequel_column_options)
        end
      end

      def modify_existing_columns(generator, current_columns)
        current_columns.each do |column|
          attrs = @db.schema(@table_name).assoc(column.name).last

          change_type    generator, attrs, column
          change_null    null_generator, attrs, column         
          change_default generator, attrs, column          
        end
      end

      def change_type(generator, attrs, column)
        new_type     = @type_converter.db_type(column)
        current_type = @type_converter.parse_type_string(attrs[:db_type])

        generator.set_column_type(column.name, new_type, column.sequel_column_options) if new_type != current_type
      end

      def change_null(generator, attrs, column)
        generator.set_column_allow_null(column.name, column.null?) if attrs[:allow_null] != column.null?
      end

      def change_default(generator, attrs, column)
        generator.set_column_default(column.name, column.default) if attrs[:ruby_default] != column.default
      end
    end
  end
end
