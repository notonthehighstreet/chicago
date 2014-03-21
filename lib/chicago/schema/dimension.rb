require 'chicago/schema/table'

module Chicago
  module Schema
    # The conventional format for dimension table names
    DIMENSION_TABLE_FORMAT = "dimension_%s".freeze

    # The conventional format for key table names.
    KEY_TABLE_FORMAT = "keys_%s".freeze

    # A dimension in the star schema.
    #
    # Dimensions contain denormalized values from various source
    # systems, and are used to group and filter the fact tables. They
    # may also be queried themselves.
    #
    # You shouldn't need to initialize a Dimension yourself - they
    # should be created via StarSchema#define_dimension.
    #
    # @api public
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

      # The table used to generate/store dimension keys.
      attr_reader :key_table_name

      # Records representing missing or not applicable dimension values.
      attr_reader :null_records

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
        @null_records.product(columns).each do |record, column|
          record[column.name] = column.default_value unless record.has_key?(column.name)
        end

        @table_name = sprintf(DIMENSION_TABLE_FORMAT, name).to_sym
        @key_table_name = sprintf(KEY_TABLE_FORMAT, @table_name).to_sym
        @predetermined_values = !! opts[:predetermined_values]
        @countable = !opts[:uncountable]
        check_null_records
      end

      # Creates null records in a Database.
      #
      # This will overwrite any records that share the id with the
      # null record, so be careful.
      #
      # Optionally provide an overridden table name, if you need to
      # create null records for a temporary version of the table.
      def create_null_records(db, overridden_table_name=nil)
        table_to_populate = overridden_table_name || table_name

        unless @null_records.empty?
          begin
            db[table_to_populate].insert_replace.
              multi_insert(@null_records)
          rescue Exception => e
            raise "Cannot populate null records for dimension #{name} (table #{table_to_populate})\n #{e.message}"
          end

          begin
            if db.table_exists?(key_table_name)
              ids = @null_records.map {|r| {:dimension_id => r[:id], :original_id => r[:original_id] || 0} }
              db[key_table_name].insert_replace.multi_insert(ids)
            end
          rescue Exception => e
            raise "Cannot populate key table records for dimension #{name} (table #{table_to_populate})\n #{e.message}"
          end
        end
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

      # Returns true if these dimension entries can be counted.
      def countable?
        @countable && identifiable?
      end

      # Returns true if the set of values for this dimension is
      # pretermined.
      #
      # Examples of this may be date dimensions, currency dimensions
      # etc.
      def has_predetermined_values?
        @predetermined_values
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
