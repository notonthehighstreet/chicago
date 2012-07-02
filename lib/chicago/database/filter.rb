require 'chicago/database/value_parser'
require 'forwardable'

module Chicago
  module Database
    class Filter
      attr_reader :column, :value

      class << self
        attr_accessor :value_parser
      end
      self.value_parser = ValueParser
      
      def self.from_hash(hash)
        case hash[:op].to_sym
        when :eq
          EqualityFilter.new(hash[:column], hash[:value])
        when :lt
          ComparisonFilter.new(hash[:column], hash[:value], :<)
        when :lte
          ComparisonFilter.new(hash[:column], hash[:value], :<=)
        when :gt
          ComparisonFilter.new(hash[:column], hash[:value], :>)
        when :gte
          ComparisonFilter.new(hash[:column], hash[:value], :>=)
        when :ne
          NotFilter.new(EqualityFilter.new(hash[:column], hash[:value]))
        when :sw
          StartsWithFilter.new(hash[:column], hash[:value])
        when :nsw
          NotFilter.new(StartsWithFilter.new(hash[:column], hash[:value]))
        when :con
          ContainsFilter.new(hash[:column], hash[:value])
        end
      end

      def initialize(column, value)
        @column = column
        @value = Filter.value_parser.new.parse(column, value)
      end

      def filter_dataset(dataset)
        column.filter_dataset(dataset, to_sequel)
      end
    end
    
    class EqualityFilter < Filter
      def to_sequel
        {@column.select_name => @value}
      end
    end

    class NotFilter < Filter
      extend Forwardable
      def_delegators :@filter, :column, :value
      
      def initialize(filter)
        @filter = filter
      end
      
      def to_sequel
        ~ @filter.to_sequel
      end
    end

    class ComparisonFilter < Filter
      def initialize(column, value, comparison)
        super column, value
        @comparison = comparison
      end
      
      def to_sequel
        @column.select_name.send(@comparison, @value)
      end
    end

    class LikeFilter < Filter
      def to_sequel
        if @value.kind_of?(Array)
          @value.inject {|a,b| like_clause(a) | like_clause(b) }
        else
          like_clause(@value)
        end
      end

      private

      def like_clause(val)
        @column.select_name.ilike( like_value(val.strip) )
      end
    end

    class StartsWithFilter < LikeFilter
      private

      def like_value(val)
        "#{val}%"
      end
    end

    class ContainsFilter < LikeFilter
      private

      def like_value(val)
        "%#{val}%"
      end
    end
  end
end
