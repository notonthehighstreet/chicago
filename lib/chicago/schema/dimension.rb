module Chicago
  module Schema
    class Dimension < StarSchemaTable
      # The name style of the dimension database tables.
      TABLE_NAME_FORMAT = "dimension_%s"

      # The name style of the key mapping database tables.
      KEY_TABLE_NAME_FORMAT = "keys_dimension_%s"

      # Returns an Array of possible identifying columns for this dimension.
      attr_reader :identifiers

      # Returns an Array of column definitions.
      attr_reader :column_definitions

      # Return the staging area table name that provides mappings between
      # original ids and dimension ids.
      #
      # This will only be created if an :original_id column is defined
      # on the dimension.
      attr_reader :key_table_name

      # Defines a dimension.
      #
      # :name - the name of the dimension
      # 
      # Options:
      #
      # :conforms_to - the name of the dimension this dimension conforms
      # to. This dimension must already be defined.
      # :block - evaluated on an instance of dimension. Use this to
      # define columns etc.
      def self.define(name, opts={}, &block)
        @definitions ||= {}
        if opts[:conforms_to] && @definitions[opts[:conforms_to]].nil?
          raise "Dimension #{opts[:conforms_to]} has not been defined" 
        end
        super
      end

      # Define a set of columns for this dimension or fact. See
      # ColumnGroupBuilder for details.
      #
      # A conformed dimension may just reference the names of the
      # columns that it uses from its 'parent' dimension.
      #
      # For example:
      #
      #    Chicago::Dimension.define(:date) do
      #      columns do
      #        date   :date
      #        year   :year
      #        string :month
      #        ...
      #      end
      #    end
      #
      #    Chicago::Dimension.define(:month, :conforms_to => :date) do
      #      columns :year, :month
      #    end
      #
      def columns(*names, &block)
        if @conforms_to
          columns = self.class.definitions.find {|dimension| dimension.name == @conforms_to }.column_definitions
          definitions = columns.select {|c| names.include?(c.name) }
          raise "Extra non-conforming columns detected" if definitions.size != names.size
          @column_definitions += definitions
        else
          @column_definitions += ColumnGroupBuilder.new(&block).column_definitions
        end
      end

      # Returns the user-friendly identifier for this record.
      def main_identifier
        @identifiers.first
      end

      # Defines one or more human-readable identifiers for this
      # dimension record.
      #
      # There is no expectation that this value will be unique, but it
      # is intended to identify a single record in a user friendly way.
      #
      # Additional identifiers are specified using :and => [:id1,
      # :id2...]
      #
      # Example, a customer might be:
      #
      #    identified_by :full_name, :and => [:email]
      def identified_by(main_id, opts={:and => []})
        @identifiers = [main_id] + opts[:and]
      end

      # Returns the schema for this dimension.
      # 
      # This includes the base table, and a key mapping table if
      # a column named :original_id is present.
      def db_schema(type_converter)      
        @tables = {}
        @tables[table_name] = base_table(type_converter)
        @tables[key_table_name] = key_table(original_key, type_converter) if original_key
        @tables
      end

      # Defines a null record for this dimension.
      #
      # Null records should be used in preference to NULL in the
      # dimension keys in the Fact tables. This allows you to
      # disambiguate between Not Applicaple and Missing values.
      #
      # Usually you will only need to include a couple of descriptive
      # attributes and use NULLs/column defaults for the rest.
      #
      # Null records should have their ids specified. An Error will be
      # raised if the attributes hash does not include an :id key.
      def null_record(attributes)
        raise "Null records must have a predefined ID" unless attributes.has_key?(:id)
        @null_records << attributes
      end
      
      # Creates the null records in the Database.
      #
      # This will overwrite any records that share the id with the
      # null record, so be careful.
      def create_null_records(db)
        db[table_name].insert_replace.insert_multiple(@null_records) unless @null_records.empty?
      end

      def original_key
        @original_key ||= @column_definitions.find {|c| c.name == :original_id }
      end

      protected
      
      # Use Dimension.define rather than constructing a Dimension manually.
      def initialize(name, opts={})
        super
        @conforms_to = opts[:conforms_to]
        @identifiers = []
        @column_definitions = []
        @table_name = sprintf(TABLE_NAME_FORMAT, name).to_sym
        @key_table_name = sprintf(KEY_TABLE_NAME_FORMAT, name).to_sym
        @null_records = []
      end

      def base_table(*args)
        table_hash = super
        # TODO: decide if this is the right way to deal with meta-data
        # style columns.
        table_hash[:columns] << {:name => :etl_batch_id, :column_type => :integer, :unsigned => true}
        table_hash
      end

      private

      def key_table(original_id, type_converter)
        {
          :primary_key => [:original_id, :dimension_id],
          :columns => [original_id.db_schema(type_converter),
                       {:name => :dimension_id, :column_type => :integer, :unsigned => true, :null => false}]
        }
      end

      def indexes
        @column_definitions.reject {|c| c.descriptive? }.inject({}) do |idx, column|
          if @natural_key.first == column.name
            idx[index_name(column.name)] = {:columns => @natural_key, :unique => true}
          else
            idx[index_name(column.name)] = {:columns => column.name}
          end
          idx
        end
      end
    end
  end
end
