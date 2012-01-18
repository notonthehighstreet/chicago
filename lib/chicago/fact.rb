require 'chicago/schema/table'

module Chicago
  class Fact < Schema::Table
    # The Dimensions associated with this fact.
    #
    # See Dimension.
    attr_reader :dimensions

    # The degenerate dimensions associated with this fact.
    #
    # Degenerate dimensions are typically ids / numbers from
    # a source system that have no associated information,
    # for example: an order number. They are used for filtering
    # and grouping facts.
    attr_reader :degenerate_dimensions

    # The measures associated with this fact.
    #
    # Measures are usually numeric values that will be aggregated, for
    # example the amount of a sale.
    attr_reader :measures

    # Creates a new fact.
    #
    # Available options:
    #
    # +dimensions+:: an array of Dimensions this fact is linked with
    # +degenerate_dimensions+:: an array of Columns
    # +measures+:: an array of Measures
    # +natual_key+:: an array of symbols, representing a uniqueness
    #                constraint on the fact
    def initialize(name, opts={})
      super
      @dimensions = opts[:dimensions] || []
      @degenerate_dimensions = opts[:degenerate_dimensions] || []
      @measures = opts[:measures] || []
      @table_name = :"facts_#{@name}"
    end

    # Returns an Array of all dimensions, degenerate_dimensions and
    # measures for this fact table.
    def columns
      @dimensions + @degenerate_dimensions + @measures
    end

    # A Factless Fact table has no measures - it used only to express a
    # relationship between a set of dimensions.
    def factless?
      @measures.empty?
    end

    # Facts accept Visitors
    def visit(visitor)
      visitor.visit_fact(self)
    end
  end
end
