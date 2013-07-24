require 'chicago/schema/named_element'

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
    # are generally defined using the schema definition DSL.
    #
    # @api public
    class Column
      include Schema::NamedElement

      # Creates a new column definition.
      #
      # name::  the name of the column.
      # column_type::  the abstract type of the column. For example, :string.
      #
      # Options:
      #
      # min::      the minimum length/number of this column.
      # max::      the maximum length/number of this column.
      # range::    any object with a min & max method - overrides min/max (above).
      # null::     whether this column can be null. False by default.
      # elements:: the allowed values this column can take.
      # default::  the default value for this column. 
      # descriptive:: whether this column is purely descriptive and
      # won't be used for grouping/filtering.
      # internal:: the column is for internal use only, and shouldn't
      #   be displayed/used directly in a user context
      # optional:: the column isn't expected to be populated.
      # calculation:: the column is not stored in the database, but
      #   calculated on demand
      #
      # @api private
      def initialize(name, column_type, opts={})
        @opts = normalize_opts(column_type, opts)
        
        super name, opts
        
        @column_type = column_type
        if @opts[:countable].kind_of?(String)
          @countable_label =  @opts[:countable]
        end
        @countable   = !! @opts[:countable]
        @min         = @opts[:min]
        @max         = @opts[:max]
        @null        = @opts[:null]
        @elements    = @opts[:elements]
        @default     = @opts[:default]
        @descriptive = !! @opts[:descriptive]
        @internal    = @opts.has_key?(:internal) ? !! @opts[:internal] : 
          column_type == :binary
        @unique      = @opts.has_key?(:unique) ? !! @opts[:unique] :
          column_type == :binary
        @optional    = !! (@opts.has_key?(:optional) ? @opts[:optional] : 
                           @opts[:null])
        @calculation = @opts[:calculation]
      end

      # Returns the type of this column. This is an abstract type,
      # not a database type (for example :string, not :varchar).
      attr_reader :column_type

      # Returns the minimum value of this column, or nil.
      attr_reader :min
      
      # Returns the minimum value of this column, or nil.
      attr_reader :max
      
      # Returns an Array of allowed elements, or nil.
      attr_reader :elements
      
      # Returns the explicit default as set in the database, or nil.
      attr_reader :default

      # Returns the Sequel calculation for this column.
      attr_reader :calculation

      # Returns the calculated default value.
      #
      # This may be different from the explicit default - for example
      # a boolean not-null column that has no explicit default will
      # have a default of nil, and a default value of false.
      #
      # The distinction is important, otherwise values can end up
      # missing in junk dimensions due to differences between what
      # ruby and the database considers unique.
      def default_value
        if @default || null?
          @default
        elsif @column_type == :boolean
          false
        elsif numeric?
          0
        elsif textual?
          ''
        else
          nil
        end
      end

      # The human-friendly label for counting items in this column.
      attr_reader :countable_label

      alias :database_name :name
      
      # Returns true if this column can be counted.
      def countable?
        @countable
      end

      # Returns true if this column should be indexed
      def indexed?
        ! (descriptive? || calculated?)
      end

      # Returns true if this column is optional.
      #
      # Will be defaulted from whether the column allows null values,
      # can be overridden (for dates etc).
      def optional?
        @optional
      end
      
      # Returns true if this column should be ignored in user-facing
      # parts of an application
      def internal?
        @internal
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

      # Returns true if this column is unique.
      def unique?
        @unique
      end

      # Returns true if this column is calculated.
      def calculated?
        !! @calculation
      end

      # Returns true if both definition's attributes are equal.
      def ==(other)
        other.kind_of?(self.class) && 
          name == other.name && 
          column_type == other.column_type && 
          @opts == other.instance_variable_get(:@opts)
      end

      # Returns true if this column stores a numeric value.
      def numeric?
        @numeric ||= [:integer, :money, :percent, :decimal, :float].include?(column_type)
      end

      # Returns true if the column stores a textual value.
      def textual?
        @textual ||= [:string, :text].include?(column_type)
      end

      # Returns true if the column stores a binary value.
      def binary?
        @binary ||= :binary == column_type
      end

      def hash #:nodoc:
        name.hash
      end

      # Returns a hash of column options.
      def to_hash
        db_schema = {
          :name => name,
          :column_type => column_type,
          :null => null?
        }
        db_schema[:default]  = default   if default || column_type == :timestamp
        db_schema[:elements] = elements  if elements
        db_schema[:size]     = size      if size
        db_schema[:unsigned] = !! unsigned? if numeric?
        db_schema
      end

      def qualify_by(table)
        name.qualify(table)
      end
      
      # Columns accept Visitors
      def visit(visitor)
        visitor.visit_column(self)
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
                  elsif column_type == :binary
                    16
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
        [:date, :timestamp, :datetime, :hash, :binary].include?(type)
      end

      def default_min(type)
        0 if type == :money
      end
    end
  end
end
