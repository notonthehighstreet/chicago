module Chicago
  module ETL
    # A definition of the columns to extract from a table in a source
    # database.
    class DatabaseSource
      extend Definable

      # Returns the name of this source.
      attr_reader :name
      
      # Returns the staging area table name.
      attr_reader :staging_table_name

      # Returns or sets the name of the table in the source database.
      attr_accessor :source_table_name

      # Returns the names of the columns that will be extracted.
      attr_reader :column_names

      # Sets the columns that will be extracted from the table.
      def columns(*names)
        @column_names += names
      end

      protected

      def initialize(name, opts)
        @name = name.to_sym
        @staging_table_name = "original_#{name.to_s}".to_sym
        @source_table_name = @name
        @column_names = []
        @filters = []
        @extract_strategy = :reimport
      end
    end
  end
end
