module Sequel
  # @private
  class Dataset
    COLUMN_DISTINCT = "DISTINCT ".freeze
    
    def distinct_expression_sql(e)
      s = ""
      distinct_expression_sql_append(s, e)
      s
    end

    def distinct_expression_sql_append(sql, e)
      sql << COLUMN_DISTINCT
      literal_append(sql, e.expression)
    end

    # Provide support for Sequel versions before 3.30.0
    unless method_defined?(:literal_append)
      def literal_append(sql, expression)
        sql << literal(expression)
      end
    end
  end
  
  module SQL
    class DistinctExpression < Expression # :nodoc:
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

    # @private
    class ComplexExpression
      include DistinctMethods
    end

    # @private
    class GenericExpression
      include DistinctMethods
    end
  end
end

# @private
class Symbol
  include Sequel::SQL::DistinctMethods
end

# @private
class String
  include Sequel::SQL::DistinctMethods
end
