module Chicago
  module Schema
    # Build relevant database tables
    class TableBuilder
      def initialize(db)
        @db = db
      end
      
      # Builds the table named +table_name+, with +columns+
      def build(table_name, columns)
        command_class = @db.table_exists?(table_name) ? AlterDbTableCommand : CreateDbTableCommand
        command_class.new(@db, table_name, columns).execute
      end
    end
  
    # A command to alter or create a table to bring it in line with a
    # set of column definitions.
    #
    # This is an Abstract class.
    class DbTableCommand
      def initialize(db, table_name, columns)
        @db = db
        @table_name = table_name
        @columns = columns
        @type_converter = TypeConverters::DbTypeConverter.for_db(@db)
      end

      # Executes the command.
      def execute
        # Overriden in subclasses
      end
    end

    # A command to alter a prexisting table.
    class AlterDbTableCommand < DbTableCommand
      def execute
        @changes_necessary = false
        generator = Sequel::Schema::AlterTableGenerator.new(@db)

        current_columns, new_columns = @columns.partition {|c| @db[@table_name].columns.include?(c.name) }
        create_new_columns(generator, new_columns)
        modify_existing_columns(generator, current_columns)
        
        @db.alter_table(@table_name, generator) if @changes_necessary
      end

      private

      def create_new_columns(generator, new_columns)
        new_columns.each do |column|
          db_column_opts = {}
          db_column_opts[:unsigned] = true if column.min && column.min >= 0
          
          generator.add_column(column.name, @type_converter.db_type(column), db_column_opts)
        end

        @changes_necessary = true unless new_columns.empty?
      end

      def modify_existing_columns(generator, current_columns)
        schema = @db.schema(@table_name)
        current_columns.each do |column|
          attrs = schema.find {|entry| entry.first == column.name }.last
          new_type     = @type_converter.db_type(column)
          current_type = @type_converter.parse_type_string(attrs[:db_type])
          if new_type != current_type
            generator.set_column_type(column.name, new_type)
            @changes_necessary = true
          end
        end
      end
    end

    # A command to create a new table.
    class CreateDbTableCommand < DbTableCommand
      def execute
        generator = Sequel::Schema::Generator.new(@db)
        @columns.each do |column|
          db_column_opts = {}
          db_column_opts[:unsigned] = true if column.min && column.min >= 0

          generator.column(column.name, @type_converter.db_type(column), db_column_opts)
        end
        @db.create_table(@table_name, :generator => generator)      
      end
    end
  end
end
