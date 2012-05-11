require 'set'

module Chicago
  module ETL
    # Wrapper around FasterCSV's output object, to convert values to a
    # format required by MySQL's LOAD DATA INFILE command.
    class MysqlDumpfileWriter
      # Creates a new writer.
      #
      # @param csv a FasterCSV output object
      # @param [Symbol] column_names columns to be output
      # @param key an optional key to ensure rows are written only once.
      def initialize(csv, column_names, key=nil)
        @csv = csv
        @column_names = column_names
        @written_rows = Set.new
        @key = key
      end

      # Writes a row to the output csv stream.
      #
      # @param Hash row Only keys in column_names will be output.
      def <<(row)
        unless written?(row)
          @csv << @column_names.map {|name| transform_value(row[name]) }
          @written_rows << row[@key]
        end
      end

      # Returns true if this row has previously been written to the
      # dumpfile.
      #
      # Always returns false if no key to determine row uniqueness has
      # been provided.
      def written?(row)
        return false if @key.nil?
        @written_rows.include?(row[@key])
      end

      private

      def transform_value(value)
        case value
        when nil
          "\\N"
        when true
          "1"
        when false
          "0"
        else
          value
        end
      end
    end
  end
end
