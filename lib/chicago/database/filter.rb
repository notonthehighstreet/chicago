module Chicago
  module Database
    class Filter
      attr_reader :column, :value
      
      def self.from_hash(hash)
        case hash[:op].to_sym
        when :eq
          EqualityFilter.new(hash[:column], hash[:value])
        when :lt
          LessThanFilter.new(hash[:column], hash[:value])
        when :lte
          LessThanOrEqualFilter.new(hash[:column], hash[:value])
        when :gt
          GreaterThanFilter.new(hash[:column], hash[:value])
        when :gte
          GreaterThanOrEqualFilter.new(hash[:column], hash[:value])
        when :ne
          NotFilter.new(EqualityFilter.new(hash[:column], hash[:value]))
        when :sw
          StartsWithFilter.new(hash[:column], hash[:value])
        when :nsw
          NotFilter.new(StartsWithFilter.new(hash[:column], hash[:value]))
        end
      end

      def initialize(column, value)
        @column, @value = column, value
      end

      def filter_dataset(dataset)
        column.filter_dataset(dataset, to_sequel)
      end
      
      protected

      def filter_value(column, value)
        if value.kind_of?(Array)
          return value.map {|v| filter_value(column, v) }
        end
        
        case column.column_type
        when :integer
          value.to_i
        when :date
          time = Chronic.parse(value, :endian_precedence => [:little, :middle])
          Date.new(time.year, time.month, time.day)
        when :datetime, :timestamp
          Chronic.parse(value, :endian_precedence => [:little, :middle])
        else
          value
        end
      end
    end

    class EqualityFilter < Filter
      def to_sequel
        {@column.select_name => filter_value(@column, @value)}
      end
    end

    class NotFilter < Filter
      def initialize(filter)
        @filter = filter
      end

      def column
        @filter.column
      end

      def value
        @filter.value
      end
      
      def to_sequel
        ~ @filter.to_sequel
      end
    end

    class LessThanFilter < Filter
      def to_sequel
        @column.select_name < filter_value(@column, @value)
      end
    end

    class GreaterThanFilter < Filter
      def to_sequel
        @column.select_name > filter_value(@column, @value)
      end
    end

    class LessThanOrEqualFilter < Filter
      def to_sequel
        @column.select_name <= filter_value(@column, @value)
      end
    end
    
    class GreaterThanOrEqualFilter < Filter
      def to_sequel
        @column.select_name >= filter_value(@column, @value)
      end
    end

    class StartsWithFilter < Filter
      def to_sequel
        if @value.kind_of?(Array)
          @value.inject {|a,b| like_clause(a) | like_clause(b) }
        else
          like_clause(@value)
        end
      end

      private

      def like_clause(val)
        @column.select_name.ilike( val.strip + "%" )
      end
    end
  end
end
