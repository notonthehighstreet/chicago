require 'chicago/errors'
require 'chicago/schema/builders/table_builder'

module Chicago::Schema::Builders
  # An API to build facts via a DSL-like syntax.
  #
  # You shouldn't need to initialize a FactBuilder yourself.
  class FactBuilder < TableBuilder
    # Builds a Fact, given the name of the fact and a definition
    # block.
    #
    # Refer to the protected methods in this block to see how to
    # define attributes of the fact.
    def build(name, &block)
      @options = {
        :dimensions => [],
        :measures => [],
        :degenerate_dimensions => []
      }
      super Chicago::Schema::Fact, name, &block
    end
    
    protected
    
    # Defines the dimensions with which a fact is associated.
    #
    # @see Fact#dimensions, Dimension
    def dimensions(*dimension_names)
      dimension_names.each do |name|
        @options[:dimensions] << find_dimension(name)
      end
    end
    
    # Defines the degenerate dimensions for this fact.
    #
    # Within the block, use the standard column definition
    # DSL, as for defining columns on a Dimension.
    #
    # @see Fact#degenerate_dimensions.
    def degenerate_dimensions(&block)
      @options[:degenerate_dimensions] += @column_builder.new(Chicago::Schema::Column).build(&block)
    end
    
    # Defines the measures for this fact.
    #
    # Within the block, use the standard column definition
    # DSL, as for defining columns on a Dimension.
    #
    # @see Fact#measures
    #
    # FIXME: By default, measures are allowed null values.
    def measures(&block)
      @options[:measures] += @column_builder.new(Chicago::Schema::Measure, :null => true).build(&block)
    end
    
    private
    
    def find_dimension(reference)
      if reference.kind_of?(Sequel::SQL::AliasedExpression)
        Chicago::Schema::DimensionReference.new(reference.aliaz,
                                        _find_dimension(reference.expression))
      else
        Chicago::Schema::DimensionReference.new(reference, _find_dimension(reference))
      end
    end
    
    def _find_dimension(name)
      @schema.dimensions.detect {|d| d.name == name } or
        raise ::Chicago::MissingDefinitionError.new "Dimension #{name} is not defined in #{@schema}"
    end
  end
end
