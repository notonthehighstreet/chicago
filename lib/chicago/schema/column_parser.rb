require 'chicago/schema/query_column'

module Chicago
  module Schema
    class ColumnParser
      def initialize(schema)
        @schema = schema
      end
      
      # Parses a column string.
      #
      # @return [Array<Column>] an array of columns. In most cases
      #   this will be a 1-element array, unless the column is
      #   pivoted.
      def parse(str)
        return parse_pivoted_column(str) if str.include?("~")
        table, col, operation = parse_parts(str)
        if operation.nil?
          [QueryColumn.column(table, col, str.to_sym)]
        else
          ref = str.sub(/\.[^.]+$/,'').to_sym
          [QueryColumn.column(table, col, ref).calculate(operation)]
        end
      end

      protected
      
      # Returns an Array of values, given a column to pivot with.
      #
      # May be overriden by subclasses
      def pivotable_elements(pivot_col)
        if pivot_col.column_type == :boolean
          [true, false]
        elsif pivot_col.elements
          pivot_col.elements
        elsif pivot_col.column_type == :integer && pivot_col.max && pivot_col.min && (pivot_col.max - pivot_col.min <= 500)
          (pivot_col.min..pivot_col.max).to_a
        else
          raise UnimplementedError.new("General pivoting not yet support")
        end
      end

      private

      def parse_parts(str)
        parts = str.split('.').map(&:to_sym)
        root = parts.shift
        table = @schema.fact(root) || @schema.dimension(root)
        
        col = table[parts.shift]

        if col.kind_of?(Chicago::Schema::Dimension)
          table = col
          new_column_name = parts.shift
          if new_column_name.nil?
            col = table
          elsif new_column_name == :count
            col = table
            parts.unshift :count
          else
            col = table[new_column_name]
          end
        end

        [table, col, parts.last]
      end

      def parse_pivoted_column(str)
        col, pivot = str.split(/\s*~\s*/)
        col_parts = col.split(".")
        operation = col_parts.pop.to_sym
        unit = [:avg, :count].include?(operation) ? nil : 0
        col = parse(col_parts.join(".")).first
        pivot_col = parse(pivot).first
        
        col.pivot(pivot_col, pivotable_elements(pivot_col), unit).map do |c|
          c.calculate(operation)
        end
      end
    end
  end
end
