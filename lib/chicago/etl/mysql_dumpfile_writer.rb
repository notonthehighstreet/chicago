module Chicago
  module ETL
    # Wrapper around FasterCSV's output object, to convert values to a
    # format required by MySQL's LOAD DATA INFILE command.
    class MysqlDumpfileWriter
      # Creates a new writer.
      #
      # @param csv a FasterCSV output object
      # @param [Symbol] column_names columns to be output
      def initialize(csv, column_names)
        @csv = csv
        @column_names = column_names
      end

      # Writes a row to the output csv stream.
      #
      # @param Hash row Only keys in column_names will be output.
      def <<(row)
        @csv << @column_names.map {|name| transform_value(row[name]) }
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
