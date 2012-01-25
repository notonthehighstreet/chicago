module Sequel
  class Dataset
    def distinct_expression_sql(e)
      "DISTINCT #{literal(e.expression)}"
    end
  end
  
  module SQL
    class DistinctExpression < Expression
      attr_reader :expression

      def initialize(expression)
        @expression = expression
      end

      to_s_method :distinct_expression_sql
    end
    
    module DistinctMethods
      def distinct
        DistinctExpression.new(self)
      end
    end

    class ComplexExpression
      include DistinctMethods
    end

    class GenericExpression
      include DistinctMethods
    end
  end
end

class Symbol
  include Sequel::SQL::DistinctMethods
end

class String
  include Sequel::SQL::DistinctMethods
end
