require 'chicago/schema/table'

module Chicago
  module Schema
    # A dimension in the star schema.
    #
    # Dimensions contain denormalized values from various source
    # systems, and are used to group and filter the fact tables. They
    # may also be queried themselves.
    #
    # You shouldn't need to initialize a Dimension yourself - they
    # should be created via StarSchema#define_dimension.
    class Dimension < Table
      # Returns an array of Columns defined on this dimension.
      #
      # @see Chicago::Schema::Column.
      attr_reader :columns

      # @deprecated Use columns instead.
      alias :column_definitions :columns
      
      # Returns all the human-friendly identifying columns for this
      # dimension.
      #
      # There is no expectation that identifying values will be unique,
      # but they are intended to identify a single record in a user
      # friendly way.
      attr_reader :identifiers

      # Creates a new Dimension, named +name+.
      #
      # @param name the name of the dimension
      # @option opts [Array] columns
      # @option opts [Array] identifiers
      # @option opts [Array] null_records an array of attribute
      #   hashes, used to create null record rows in the database.
      #   Hashes must have an :id key.
      # @option opts [Array<Symbol>] natual_key an array of symbols,
      #   representing a uniqueness constraint on the dimension.
      # @option opts description a long text description about the dimension.
      # @raise [Chicago::UnsafeNullRecordError] 
      def initialize(name, opts={})
        super
        @columns = opts[:columns] || []
        @identifiers = opts[:identifiers] || []
        @null_records = opts[:null_records] || []
        @table_name = "dimension_#{@name}".to_sym
        check_null_records
      end

      # Creates null records in a Database.
      #
      # This will overwrite any records that share the id with the
      # null record, so be careful.
      def create_null_records(db)
        db[table_name].insert_replace.insert_multiple(@null_records) unless @null_records.empty?
      end

      # Returns the main identifier for this record.
      def main_identifier
        @identifiers.first
      end

      # Returns true if this dimension can be identified as a concrete
      # entity, with an original_id from a source system.
      # 
      # @todo change to be consistent with identifiers
      def identifiable?
        !! original_key
      end

      # Returns the column that represents the id in the original
      # source for the dimension.
      #
      # Currently this column *must* be called +original_id+
      #
      # @todo make configurable.
      def original_key
        @original_key ||= @columns.detect {|c| c.name == :original_id }
      end

      # Dimensions accept Visitors
      def visit(visitor)
        visitor.visit_dimension(self)
      end
      
      private

      def check_null_records
        unless @null_records.all? {|h| h[:id] }
          raise UnsafeNullRecordError.new "Null record defined without id field for dimension #{name}"
        end
      end
    end
  end
end
