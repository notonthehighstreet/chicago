module Chicago
  module Database
    class ValueParser
      def parse(column, value)
        if value.kind_of?(Array)
          return value.map {|v| parse(column, v) }
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
  end
end
