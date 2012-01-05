require 'delegate'

module Chicago
  module Schema
    # A column in a dimension or fact record.
    #
    # The column definition is used to generate the options
    # to create the column in the database schema, but also
    # to provide an abstract definition of the column for views
    # and other Data Warehouse code.
    #
    # You shouldn't need to create a Column manually - they
    # are generally defined using the DSL on Dimension or Fact.
    class Column
      # Creates a new column definition.
      #
      # owner: the owning fact or dimension
      # name:  the name of the column.
      # column_type:  the abstract type of the column. For example, :string.
      #
      # Options:
      #
      # min:      the minimum length/number of this column.
      # max:      the maximum length/number of this column.
      # range:    any object with a min & max method - overrides min/max (above).
      # null:     whether this column can be null. False by default.
      # elements: the allowed values this column can take.
      # default:  the default value for this column. 
      # descriptive: whether this column is purely descriptive and
      # won't be used for grouping/filtering.
      # semi_additive: whether a measure column is semi_additive.
      def initialize(owner, name, column_type, opts={})
        @opts = normalize_opts(column_type, opts)

        @owner       = owner
        @name        = name
        @column_type = column_type
        @label       = @opts[:label] || name.to_s.titlecase
        @countable_label = @opts[:countable].kind_of?(String) ? @opts[:countable] : @label
        @countable   = !! @opts[:countable]
        @min         = @opts[:min]
        @max         = @opts[:max]
        @null        = @opts[:null]
        @elements    = @opts[:elements]
        @default     = @opts[:default]
        @descriptive = !! @opts[:descriptive]
        @semi_additive = !! @opts[:semi_additive]
        @internal    = !! @opts[:internal]
      end

      # Returns the owning Fact or Dimension
      attr_reader :owner
      
      # Returns the name of this column.
      attr_reader :name

      # Returns the type of this column. This is an abstract type,
      # not a database type (for example :string, not :varchar).
      attr_reader :column_type

      # Returns the minimum value of this column, or nil.
      attr_reader :min

      # Returns the minimum value of this column, or nil.
      attr_reader :max

      # Returns an Array of allowed elements, or nil.
      attr_reader :elements

      # Returns the default value for this column, or nil.
      attr_reader :default

      # Returns a human-friendly version of the column name.
      attr_reader :label

      attr_reader :countable_label

      # Returns true if this column can be counted.
      def countable?
        @countable
      end

      # Returns true if this column should be ignored in user-facing
      # parts of an application
      def internal?
        @internal
      end
      
      # Returns a qualified symbol name, for use with Sequel as an SQL reference
      def sql_name
        @sql_name ||= name.qualify(owner.table_name).as(qualified_name)
      end

      def sql_group_name
        qualified_name.to_sym
      end
      
      def sql_order_name
        name.qualify(owner.table_name)
      end
      
      # Returns true if this measure column can be averaged, but not summed.
      def semi_additive?
        @semi_additive
      end

      # Returns true if null values are allowed.
      def null?
        @null
      end

      # Returns true if this column is just informational, and is not
      # intended to be used as a filter.
      def descriptive?
        @descriptive
      end

      # Returns true if both definition's attributes are equal.
      def ==(other)
        other.kind_of?(self.class) && 
          name == other.name && 
          column_type == other.column_type && 
          @opts == other.instance_variable_get(:@opts)
      end

      # Returns a hash of column options for a Sequel column
      def db_schema(type_converter)
        db_schema = {
          :name => name,
          :column_type => type_converter.db_type(self),
          :null => null?
        }
        db_schema[:default]  = default   if default || column_type == :timestamp
        db_schema[:elements] = elements  if elements
        db_schema[:size]     = size      if size
        db_schema[:unsigned] = !! unsigned? if numeric?
        db_schema
      end

      # Returns true if this column stores a numeric value.
      def numeric?
        @numeric ||= [:integer, :money, :percent, :decimal, :float].include?(column_type)
      end

      def hash #:nodoc:
        name.hash
      end

      # Returns the abstract qualified version of this column, for
      # example "product.title".
      def qualified_name
        [owner.name, name] * '.'
      end
      
      def to_s
        qualified_name
      end
      
      private
      
      def unsigned?
        return @unsigned if defined? @unsigned      
        default_unsigned = column_type == :percent || column_type == :money
        @unsigned = min ? min >= 0 : default_unsigned
      end

      def size
        @size ||= if @opts[:size]
                    @opts[:size]
                  elsif max && column_type == :string
                    max
                  elsif column_type == :money
                    [12,2]
                  elsif column_type == :percent
                    [6,3]
                  end
      end

      def normalize_opts(type, opts)
        opts = {:null => default_null(type), :min => default_min(type)}.merge(opts)
        if opts[:range]
          opts[:min] = opts[:range].min
          opts[:max] = opts[:range].max
          opts.delete(:range)
        end
        opts
      end

      def default_null(type)
        [:date, :timestamp, :datetime].include?(type)
      end

      def default_min(type)
        0 if type == :money
      end
    end

    # Decorates a column to provide the illusion that a dimension is a
    # column.
    class DimensionAsColumn < DelegateClass(Column)
      def countable_label
        "No. of #{owner.label.pluralize}"
      end
      
      def label
        owner.label
      end

      def name
        owner.name
      end

      def qualified_name
        name.to_s
      end

      def to_s
        qualified_name
      end

      def sql_name
        __getobj__.name.qualify(owner.table_name).as(qualified_name)
      end

      def sql_group_name
        original_id_column = owner.original_key

        if original_id_column
          original_id_column.name.qualify(owner.table_name)
        end
      end

      def sql_order_name
        owner.main_identifier.qualify(owner.table_name)
      end
    end

    class CalculatedColumn < DelegateClass(Column)
      def initialize(column, operation)
        @operation = operation
        super column
      end

      def label
        if @operation == :count
          __getobj__.countable_label
        else
          __getobj__.label
        end
      end
      
      def qualified_name
        [@operation,__getobj__.qualified_name] * '.'
      end

      def to_s
        qualified_name
      end

      def sql_name
        if @operation.to_sym == :count
          # Yuk
          if __getobj__.kind_of?(DimensionAsColumn)
            table = __getobj__.sql_group_name.table
            field = __getobj__.sql_group_name.column
          else
            table = __getobj__.sql_name.expression.table
            field = __getobj__.sql_name.expression.column
          end
          :count.sql_function("distinct `#{table}`.`#{field}`".lit).as(qualified_name)
        else
          @operation.sql_function(__getobj__.sql_name.expression).as(qualified_name)
        end
      end

      def sql_group_name
      end

      def sql_order_name
        sql_name.expression
      end
    end
  end
end
