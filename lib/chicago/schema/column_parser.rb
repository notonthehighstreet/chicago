module Chicago
  module Schema
    class ColumnDecorator
      instance_methods.each do |m|
        undef_method m unless m =~ /(^__|^send$|^object_id$)/
      end

      def initialize(column)
        @column = column
      end

      def method_missing(*args, &block)
        @column.send(*args, &block)
      end
    end
    
    class QualifiedColumn < ColumnDecorator
      def initialize(owner, column, column_alias)
        super column
        @owner = owner
        @column_alias = column_alias

        if @column.kind_of?(Chicago::Schema::Dimension)
          @select_name = @column.main_identifier.qualify(@column.name)
          @count_name  = @column.original_key.name.qualify(@column.name)
          @group_name  = @column.original_key.name.qualify(@column.name)
        elsif @owner.kind_of?(Chicago::Schema::Dimension) && @owner.identifiable? && @owner.identifiers.include?(@column.name)
          @select_name = @column.name.qualify(@owner.name)
          @count_name  = @owner.original_key.name.qualify(@owner.name)
          @group_name  = @owner.original_key.name.qualify(@owner.name)
        else
          @select_name = @column.name.qualify(@owner.name)
          @count_name = @select_name
          @group_name = column_alias
        end
      end
      
      attr_reader :owner, :select_name, :column_alias, :group_name, :count_name
    end

    class CalculatedColumn < ColumnDecorator
      def self.build(operation, column)
        if operation == :count
          CountColumn.new(column)
        else
          SqlSimpleAggregateColumn.new(column, operation)
        end
      end

      def initialize(column, operation)
        super column
        @operation = operation
        @defined_operation = operation
        normalize_operation
      end

      def column_alias
        "#{@column.column_alias}.count".to_sym
      end

      def group_name
        nil
      end

      private

      def normalize_operation
        @operation = :var_samp if @operation == :variance
        @operation = :stddev_samp if @operation == :stddev     
      end
    end

    class SqlSimpleAggregateColumn < CalculatedColumn      
      def select_name
        @operation.sql_function(@column.select_name)
      end

      def column_alias
        "#{@column.column_alias}.#{@defined_operation}".to_sym
      end
    end

    class CountColumn < CalculatedColumn
      def initialize(column)
        super column, :count
      end
      
      def select_name
        :count.sql_function(@column.count_name.distinct)
      end
      
      def label
        "No. of #{@column.label.pluralize}"
      end
    end

    class PivotedColumn < ColumnDecorator
      def initialize(column, pivoted_by, index, value, unit=0)
        super column
        @pivoted_column = pivoted_by
        @index = index
        @value = value
        @unit = unit
      end

      def label
        @value
      end
      
      def owner
        @pivoted_column.owner
      end
      
      def column_alias
        "#{@column.column_alias}.#{@index}".to_sym
      end

      def group_name
        nil
      end

      def select_name
        :if.sql_function({@pivoted_column.select_name => @value}, @column.select_name, @unit)
      end

      def count_name
        :if.sql_function({@pivoted_column.select_name => @value}, @column.count_name, @unit)
      end
    end

    class ColumnParser
      def initialize(schema)
        @schema = schema
      end
      
      def parse(str)
        if str.include?("~")
          col, pivot = str.split(/\s*~\s*/)
          col_parts = col.split(".")
          operation = col_parts.pop.to_sym
          unit = [:avg, :count].include?(operation) ? nil : 0
          col = parse(col_parts.join("."))
          pivot_col = parse(pivot)

          if pivot_col.column_type == :boolean
            elements = [true, false]
          elsif pivot_col.elements
            elements = pivot_col.elements
          elsif pivot_col.column_type == :integer && pivot_col.max && pivot_col.min && (pivot_col.max - pivot_col.min <= 500)
            elements = (pivot_col.min..pivot_col.max).to_a
          else
            raise UnimplementedError.new("General pivoting not yet support")
          end

          return elements.zip((0..elements.size).to_a).map do |e,i|
            CalculatedColumn.build(operation,
                                   PivotedColumn.new(col,
                                                     pivot_col, i, e, unit))
          end
        end
        
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

        if parts.empty?
          QualifiedColumn.new(table, col, str.to_sym)
        else
          new_parts = str.split(".")
          new_parts.pop
          CalculatedColumn.build(parts.shift,
                                 QualifiedColumn.new(table, col, new_parts.join(".").to_sym))
        end
      end
    end
  end
end
