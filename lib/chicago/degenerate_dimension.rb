require 'chicago/column'

module Chicago
  class DegenerateDimension < Column
    # Degenerate dimensions are visitable
    def visit(visitor)
      visitor.visit_degenerate_dimension(self)
    end
  end
end
