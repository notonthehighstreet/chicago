module Chicago
  module Schema
    # Decorates/adapts Columns so they can be used in SQL statements
    # and in a User Interface.
    #
    # Generate with the column method:
    #
    #     QueryColumn.column(owner, column, "some.alias")
    #
    # @abstract
    class QueryColumn
      instance_methods.each do |m|
        undef_method m unless m =~ /(^__|^send$|^object_id$)/
      end

      # @private
      def initialize(column)
        @column = column
      end

      # @private
      def method_missing(*args, &block)
        @column.send(*args, &block)
      end

      # Factory method that returns a query column.
      #
      # @param owner the column owner, normally a fact or dimension
      # @param column the wrapped column
      # @param column_alias the reference to this column as used by
      #   the column parser.
      def self.column(owner, column, column_alias)
        if column.kind_of?(Chicago::Schema::Dimension)
          DimensionAsColumn.new(owner, column, column_alias)
        elsif owner.kind_of?(Chicago::Schema::Dimension) && owner.identifiable? && owner.identifiers.include?(column.name)
          DimensionIdentifierColumn.new(owner, column, column_alias)
        elsif column.calculated?
          VirtualColumn.new(owner, column, column_alias)
        else
          QualifiedColumn.new(owner, column, column_alias)
        end
      end

      def filter_dataset(ds, filter)
        ds.filter(filter)
      end
    end

    # @abstract
    class AbstractQualifiedColumn < QueryColumn
      def initialize(owner, column, column_alias)
        super column
        @owner = owner
        @column_alias = column_alias
      end
      attr_reader :owner, :select_name, :column_alias, :group_name, :count_name

      def pivot(pivot_col, elements, unit)
        elements.zip((0..elements.size).to_a).map do |e,i|
          PivotedColumn.new(self, pivot_col, i, e, unit)
        end
      end

      def calculate(operation)
        CalculatedColumn.make(operation, self)
      end
    end

    class DimensionAsColumn < AbstractQualifiedColumn
      def initialize(owner, column, column_alias)
        super
        @select_name = @column.main_identifier.qualify(@column.name)
        @count_name  = @column.original_key.name.qualify(@column.name)
        @group_name  = @column.original_key.name.qualify(@column.name)
      end
    end

    class DimensionIdentifierColumn < AbstractQualifiedColumn
      def initialize(owner, column, column_alias)
        super
        @select_name = @column.name.qualify(@owner.name)
        @count_name  = @owner.original_key.name.qualify(@owner.name)
        @group_name  = @owner.original_key.name.qualify(@owner.name)
      end
    end
    
    class QualifiedColumn < AbstractQualifiedColumn
      def initialize(owner, column, column_alias)
        super
        @select_name = @column.name.qualify(@owner.name)
        @count_name = @select_name
        @group_name = column_alias.to_sym
      end
    end

    # Allows querying a column that doesn't exist in the database, but
    # is defined as a calculation in the column definition.
    class VirtualColumn < QualifiedColumn
      def initialize(owner, column, column_alias)
        super(owner, column, column_alias)
        @select_name = @column.calculation
      end

      def group_name
        nil
      end
    end

    # @abstract
    class CalculatedColumn < QueryColumn
      def self.make(operation, column)
        if operation == :count
          CountColumn.new(column)
        else
          AggregateColumn.new(column, operation)
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

      def filter_dataset(ds, filter)
        ds.having(filter)
      end

      private

      def normalize_operation
        @operation = :var_samp if @operation == :variance
        @operation = :stddev_samp if @operation == :stddev     
      end
    end

    class AggregateColumn < CalculatedColumn
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
        if @column.label.kind_of?(Array)
          new_label = @column.label.dup
          new_label[0] = @column.countable_label || "No. of #{@column.label.first.pluralize}"
          new_label
        else
          @column.countable_label || "No. of #{@column.label.pluralize}"
        end
      end
    end

    class PivotedColumn < QueryColumn
      def initialize(column, pivoted_by, index, value, unit=0)
        super column
        @pivoted_column = pivoted_by
        @index = index
        @value = value
        @unit = unit
      end

      def calculate(operation)
        CalculatedColumn.make(operation, self)
      end
      
      def label
        [@column.label, @value]
      end
      
      def owner
        [@pivoted_column.owner, @column.owner]
      end
      
      def column_alias
        "#{@column.column_alias}:#{@pivoted_column.column_alias}.#{@index}".to_sym
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
  end
end
