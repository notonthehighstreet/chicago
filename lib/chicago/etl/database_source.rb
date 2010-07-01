module Chicago
  module ETL
    # A definition of the columns to extract from a table in a source
    # database.
    class DatabaseSource
      extend Definable

      # Returns the name of this source.
      attr_reader :name
      
      # Returns/Sets the staging area table name.
      attr_accessor :table_name

      # Returns the names of the columns that will be extracted.
      attr_reader :column_names

      # Sets the columns that will be extracted from the table.
      def columns(*names)
        @column_names += names
      end
      
      protected

      def initialize(name, opts)
        @name = name.to_sym
        @table_name = "original_#{name.to_s}".to_sym
        @column_names = []
      end
    end
  end
end
