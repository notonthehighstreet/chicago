module Chicago
  class Dimension < StarSchemaTable
    # Returns an Array of possible identifying columns for this dimension.
    attr_reader :identifiers

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
      @table_name = "#{name}_dimension".to_sym
    end
  end
end
