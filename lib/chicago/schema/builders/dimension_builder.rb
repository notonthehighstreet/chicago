require 'chicago/schema/builders/table_builder'

module Chicago::Schema::Builders
  class DimensionBuilder < TableBuilder
    # Builds a Dimension, given the name of the fact and a definition
    # block.
    #
    # Refer to the protected methods in this class to see how to
    # define attributes of the dimension in the passed block.
    def build(name, &block)
      @options = {
        :columns => [],
        :null_records => [],
        :identifiers => []
      }
      super Chicago::Schema::Dimension, name, &block
    end

    protected

    # Define a set of columns for this dimension or fact. See
    # Chicago::Schema::Builders::ColumnBuilder for details.
    def columns(&block)
      @options[:columns] += @column_builder.new(Chicago::Schema::Column).build(&block) if block_given?
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
      @options[:null_records] << attributes
    end

    # Defines one or more human-readable identifiers for this
    # dimension record.
    #
    # Additional identifiers are specified using :and => [:id1,
    # :id2...]
    #
    # Example, a customer might be:
    #
    #    identified_by :full_name, :and => [:email]
    #
    # See Chicago::Schema::Dimension#identifiers
    def identified_by(main_id, opts={:and => []})
      @options[:identifiers] = [main_id] + opts[:and]
    end
  end
end
