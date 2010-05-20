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
      end
    end

    class AlterDbTableCommand < DbTableCommand
      def execute
        generator = Sequel::Schema::AlterTableGenerator.new(@db)
        new_columns = @columns.reject {|c| @db[@table_name].columns.include?(c.name) }
        unless new_columns.empty?
          new_columns.each do |column|
            generator.add_column(column.name, column.type)
          end
          @db.alter_table(@table_name, generator)
        end
      end
    end

    class CreateDbTableCommand < DbTableCommand
      def execute
        generator = Sequel::Schema::Generator.new(@db)
        @columns.each do |column|
          generator.column(column.name, column.type)
        end
        @db.create_table(@table_name, :generator => generator)      
      end
    end
  end
end
