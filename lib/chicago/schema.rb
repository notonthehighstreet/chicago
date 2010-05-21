module Chicago
  module Schema
    class TableBuilder
      def initialize(db)
        @db = db
      end
      
      def build(table_name, columns)
        command_class = @db.table_exists?(table_name) ? AlterDbTableCommand : CreateDbTableCommand
        command_class.new(@db, table_name, columns).execute
      end
    end
  
    class DbTableCommand
      def initialize(db, table_name, columns)
        @db = db
        @table_name = table_name
        @columns = columns
        @type_converter = TypeConverters::DbTypeConverter.for_db(@db)
      end
    end

    class AlterDbTableCommand < DbTableCommand
      def execute
        changes_necessary = false
        generator = Sequel::Schema::AlterTableGenerator.new(@db)
        schema = @db.schema(@table_name)
        columns = schema.map {|c| c.first }

        current_columns, new_columns = @columns.partition {|c| columns.include?(c.name) }

        unless new_columns.empty?
          new_columns.each do |column|
            db_column_opts = {}
            db_column_opts[:unsigned] = true if column.min && column.min >= 0

            generator.add_column(column.name, @type_converter.db_type(column), db_column_opts)
          end
          changes_necessary = true
        end

        current_columns.each do |column|
          attrs = schema.find {|entry| entry.first == column.name }.last
          new_type     = @type_converter.db_type(column)
          current_type = @type_converter.parse_type_string(attrs[:db_type])
          if new_type != current_type
            generator.set_column_type(column.name, new_type)
            changes_necessary = true
          end
        end
        
        @db.alter_table(@table_name, generator) if changes_necessary
      end
    end

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
