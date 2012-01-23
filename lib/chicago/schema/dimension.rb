require 'chicago/schema/table'

module Chicago
  module Schema
    class Dimension < Table
      # Returns an array of Columns defined on this dimension.
      #
      # See Column.
      attr_reader :columns

      # Deprecated. Use columns instead.
      # TODO: remove.
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
      # Available options:
      #
      # columns:: an array of columns for this dimension.
      # identifiers:: an array of columns.
      # null_records:: an array of attribute hashes, used to create null
      #                record rows in the database. Hashes must have an
      #                :id key.
      # +natual_key+:: an array of symbols, representing a uniqueness
      #                constraint on the dimension.
      #
      # May raise a Chicago::UnsafeNullRecordError.
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
      # DEPRECATED.
      # TODO: change to be consistent with identifiers
      def identifiable?
        !! original_key
      end

      # DEPRECATED
      # TODO: at least make configurable.
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
