module Chicago
  class Dimension < StarSchemaTable
    # Returns an Array of possible identifying columns for this dimension.
    attr_reader :identifiers

    # Returns an Array of column definitions.
    attr_reader :column_definitions

    # Define a set of columns for this dimension or fact. See
    # ColumnGroupBuilder for details.
    def columns(&block)
      @column_definitions += Schema::ColumnGroupBuilder.new(&block).column_definitions
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
    def db_schema(type_converter)      
      { table_name => {
          :primary_key => :id,
          :table_options => type_converter.dimension_table_options,
          :columns => [{:name => :id, :column_type => :integer, :unsigned => true}] + column_definitions.map {|c| c.db_schema(type_converter) }
        }
      }
    end
      
    protected

    def initialize(name)
      super
      @identifiers = []
      @column_definitions = []
      @table_name = "#{name}_dimension".to_sym
    end
  end
end
