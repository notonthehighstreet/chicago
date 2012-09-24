require 'chicago/schema/column'

module Chicago
  module Schema
    # @api public
    class Measure < Column
      # Creates a measure.
      #
      # Additional options:
      #
      # semi_additive:: whether a measure column is semi_additive.
      #
      # See Chicago::Schema::Column
      def initialize(name, column_type, opts={})
        super
        @semi_additive = !! opts[:semi_additive]
      end

      # Returns false. Measures do not need to be indexed.
      def indexed?
        false
      end
      
      # Returns true if this measure can be averaged, but not summed.
      def semi_additive?
        @semi_additive
      end

      # Measures are visitable
      def visit(visitor)
        visitor.visit_measure(self)
      end
    end
  end
end
