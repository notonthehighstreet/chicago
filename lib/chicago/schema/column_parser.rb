require 'chicago/schema/query_column'

module Chicago
  module Schema
    # Parses AST column representations, returning an Array of
    # QueryColumns.
    #
    # Columns can be simple dotted references, like
    #
    #     "sales.product.name"
    #
    # calculations like:
    #
    #     {:column => "sales.total", :op => "sum"}
    #
    # or pivoted calculations like:
    #
    #     {:column => "sales.total",
    #      :op => "sum"
    #      :pivot => "sales.date.year"}
    #
    class ColumnParser
      # Creates a new ColumnParser for a schema.
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
      # May be overridden by subclasses.
      #
      # @raise UnimplementedError if a column with unknown or too many
      #   elements is used as a pivot column. In future this
      #   restriction may be lifted.
      def pivotable_elements(pivot_col)
        if pivot_col.column_type == :boolean
          [true, false]
        elsif pivot_col.elements
          pivot_col.elements
        elsif has_pivotable_integer_range?(pivot_col)
          (pivot_col.min..pivot_col.max).to_a
        else
          raise UnimplementedError.new("General pivoting not yet support")
        end
      end

      # Returns true if an Integer column can be used as pivot column.
      #
      # Default is to allow columns with a range 500 wide or less to
      # be used as pivot columns.
      #
      # May be overridden by subclasses
      #
      # @return Boolean true if this column can be pivoted.
      def has_pivotable_integer_range?(pivot_col)
        pivot_col.column_type == :integer &&
          pivot_col.max &&
          pivot_col.min &&
          (pivot_col.max - pivot_col.min <= 500)
      end

      private

      def _parse(elem)
        elem.kind_of?(Hash) ? complex_column(elem) : simple_column(elem)
      end

      def complex_column(elem)
        elem.symbolize_keys!
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
        table, col, table_qualifier = parse_parts(elem)
        QueryColumn.column(table, col, elem.to_sym, table_qualifier)
      end
  
      def calculated_column(elem)
        col = _parse(elem[:column])
        elem[:op] ? col.calculate(elem[:op].to_sym) : col
      end

      def parse_parts(str)
        table, parts = parse_table(str)
        col = table[parts.shift]
        # To cope with bare dimension references.
        col = table.original_key if col.nil?
        
        if col.kind_of?(Chicago::Schema::Dimension)
          table = col
          col = parts.empty? ? table : table[parts.first]
          table_qualifier = table.label if table.roleplayed?
        end

        [table, col, table_qualifier]
      end

      def parse_table(str)
        parts = str.split('.').map(&:to_sym)
        root = parts.shift
        table = @schema.fact(root) || @schema.dimension(root)
        [table, parts]
      end
    end
  end
end
