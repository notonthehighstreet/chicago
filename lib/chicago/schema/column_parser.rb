require 'chicago/schema/query_column'

module Chicago
  module Schema
    class ColumnParser
      def initialize(schema)
        @schema = schema
      end
      
      # Parses a column element. An element may be a string reference
      # like "foo.bar", or more complicated like {:column =>
      # "foo.bar", :op => "sum"}
      #
      # @return [Array<Column>] an array of columns. In most cases
      #   this will be a 1-element array, unless the column is
      #   pivoted.
      def parse(elem)
        [_parse(elem)].flatten
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

      def _parse(elem)
        elem.kind_of?(Hash) ? complex_column(elem) : simple_column(elem)
      end

      def complex_column(elem)
        elem[:pivot] ? pivoted_column(elem) : calculated_column(elem)
      end

      def pivoted_column(elem)
        pivoted_column = _parse(elem[:column])
        pivoted_by = _parse(elem[:pivot])
        unit = [:avg, :count].include?(elem[:op].to_sym) ? nil : 0
        pivoted_column.pivot(pivoted_by, pivotable_elements(pivoted_by), unit).map do |c|
          c.calculate(elem[:op].to_sym)
        end
      end

      def simple_column(elem)
        table, col = parse_parts(elem)
        QueryColumn.column(table, col, elem.to_sym)
      end
  
      def calculated_column(elem)
        col = _parse(elem[:column])
        elem[:op] ? col.calculate(elem[:op].to_sym) : col
      end

      def parse_parts(str)
        parts = str.split('.').map(&:to_sym)
        root = parts.shift
        table = @schema.fact(root) || @schema.dimension(root)
        
        col = table[parts.shift]

        if col.kind_of?(Chicago::Schema::Dimension)
          table = col
          col = parts.empty? ? table : table[parts.first]
        end

        [table, col]
      end
    end
  end
end
