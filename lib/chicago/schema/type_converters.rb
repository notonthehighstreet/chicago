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
        # Currently onyl supports MySql-specific types
        def self.for_db(db)
          return MysqlTypeConverter.new if db.database_type == :mysql

          self.new
        end

        # Returns a db type given a column definition
        def db_type(column)
          db_type = column.column_type
          db_type = integer_type(column.min, column.max) if column.column_type == :integer
          db_type
        end

        # Returns a database integer column type, big enough to fit
        # values between min and max, or integer if a specific type
        # cannot be found.
        #
        # May raise an ArgumentError if min or max is too large for a
        # single database column.
        def integer_type(min, max)
          if min && max && ((min >= -32_768 && max <= 32_767) || (min >= 0 && max <= 65_535))
            :smallint
          else
            :integer
          end
        end

        def parse_type_string(str)
        end
      end

      # MySql-specific type conversion strategy
      class MysqlTypeConverter < DbTypeConverter
        # Returns a db type symbol, such as :smallint or :varchar from
        # a type string as produced by a Sequel #schema call.
        def parse_type_string(str)
          case str
          when /^tinyint\(1\)/ then :boolean
          when /^tinyint/      then :tinyint
          when /^smallint/     then :smallint
          when /^mediumint/    then :mediumint
          when /^int/          then :integer
          when /^bigint/       then :bigint
          end
        end

        def integer_type(min, max)
          return :integer unless min && max

          case
          when in_numeric_range?(min, max, 256)                        then :tinyint
          when in_numeric_range?(min, max, 65_536)                     then :smallint
          when in_numeric_range?(min, max, 16_777_216)                 then :mediumint
          when in_numeric_range?(min, max, 4_294_967_296)              then :integer
          when in_numeric_range?(min, max, 18_446_744_073_709_551_616) then :bigint
          else
            raise ArgumentError.new("#{min} is too small or #{max} is too large for a single column")
          end
        end

        private

        def in_numeric_range?(min, max, unsigned_limit)
          signed_limit = unsigned_limit / 2
          (min >= -signed_limit && max <= signed_limit - 1)  ||  (min >= 0 && max <= unsigned_limit - 1)
        end
      end
    end
  end
end