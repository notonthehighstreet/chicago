module Chicago
  module Schema
    module TypeConverters
      # Generic type conversion strategy.
      #
      # This supplements Sequel's type conversion strategy rather than
      # replaces it, so :boolean will still return :boolean rather
      # than tinyint(1) in the case of mysql.
      class DbTypeConverter
        # Returns an appropriate type conversion stratgey for the given
        # database, +db+.
        #
        # If a database-specific strategy cannot be found, returns a
        # generic strategy.
        #
        # Currently only supports MySql-specific types
        def self.for_db(db)
          return MysqlTypeConverter.new if db.database_type == :mysql

          self.new
        end

        # Returns a db type given a column definition
        def db_type(column)
          case column.column_type
          when :integer then integer_type(column.min, column.max)
          when :string  then string_type(column.min, column.max)
          when :money   then :decimal
          else
            column.column_type
          end
        end

        def string_type(min, max)
          min && max && min == max ? :char : :varchar 
        end
            
        # Returns a database integer column type, big enough to fit
        # values between min and max, or integer if a specific type
        # cannot be found.
        #
        # May raise an ArgumentError if min or max is too large for a
        # single database column.
        def integer_type(min, max)
          signed_limit = (SMALL_INT_MAX + 1) / 2
          if min && max && ((min >= -signed_limit && max <= signed_limit - 1) || (min >= 0 && max <= SMALL_INT_MAX))
            :smallint
          else
            :integer
          end
        end

        # Returns a db type symbol, such as :smallint or :varchar from
        # a type string as produced by a Sequel #schema call.
        def parse_type_string(str)
        end

        # Returns true if the database column is unsigned.
        def parse_type_unsigned(str)
          str.include?("unsigned")
        end
      end

      # MySql-specific type conversion strategy
      class MysqlTypeConverter < DbTypeConverter
        def db_type(column)
          return :enum if column.elements && column.elements.size < 65_536
          super
        end

        def parse_type_string(str)
          case str
          when /^tinyint\(1\)/ then :boolean
          when /^int/          then :integer
          when /^([^(]+)/      then $1.to_sym
          end
        end

        def parse_type_size(str)
          str =~ /\(([^)]+)\)/
          s = $1.split(",").map {|i| i.to_i }
          s.size == 1 ? s.first : s
        end

        def integer_type(min, max)
          return :integer unless min && max

          case
          when in_numeric_range?(min, max, TINY_INT_MAX)   then :tinyint
          when in_numeric_range?(min, max, SMALL_INT_MAX)  then :smallint
          when in_numeric_range?(min, max, MEDIUM_INT_MAX) then :mediumint
          when in_numeric_range?(min, max, INT_MAX)        then :integer
          when in_numeric_range?(min, max, BIG_INT_MAX)    then :bigint
          else
            raise ArgumentError.new("#{min} is too small or #{max} is too large for a single column")
          end
        end

        private

        def in_numeric_range?(min, max, unsigned_limit)
          signed_limit = (unsigned_limit + 1) / 2
          (min >= -signed_limit && max <= signed_limit - 1)  ||  (min >= 0 && max <= unsigned_limit)
        end
      end
    end
  end
end
