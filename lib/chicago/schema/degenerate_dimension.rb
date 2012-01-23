require 'chicago/schema/column'

module Chicago
  module Schema
    class DegenerateDimension < Column
      # Degenerate dimensions are visitable
      def visit(visitor)
        visitor.visit_degenerate_dimension(self)
      end
    end
  end
end
