require 'chicago/schema/builders/table_builder'

module Chicago::Schema::Builders
  class DimensionBuilder < TableBuilder
    # Builds a Dimension, given the name of the fact and a definition
    # block.
    #
    # Refer to the protected methods in this block to see how to
    # define attributes of the dimension.
    def build(name, &block)
      @options = {
        :columns => [],
        :null_records => [],
        :identifiers => []
      }
      super Chicago::Dimension, name, &block
    end

    protected

    def columns(&block)
      @options[:columns] += @column_builder.new.build(&block) if block_given?
    end

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
    # See Chicago::Dimension#identifiers
    def identified_by(main_id, opts={:and => []})
      @options[identifiers] = [main_id] + opts[:and]
    end
  end
end
