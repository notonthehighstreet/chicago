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
          case db.database_type
          when :mysql then MysqlTypeConverter.new
          else
            self.new
          end
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
      end

      # MySql-specific type conversion strategy
      class MysqlTypeConverter < DbTypeConverter
        def integer_type(min, max)
          return :integer unless min && max
          
          case
          when (min >= -128 && max <= 127) || (min >= 0 && max <= 255)
            :tinyint
          when (min >= -32_768 && max <= 32_767) || (min >= 0 && max <= 65_535)
            :smallint
          when (min >= -8_388_608 && max <= 8_388_607) || (min >= 0 && max <= 16_777_215)
            :mediumint
          when (min >= -2_147_483_648 && max <= 2_147_483_647) || (min >= 0 && max <= 4_294_967_295)
            :integer
          when (min >= -9_223_372_036_854_775_808 && max <= 9_223_372_036_854_775_807) || (min >= 0 && max <= 18_446_744_073_709_551_615)
            :bigint
          else
            raise ArgumentError.new("#{min} is too small or #{max} is too large for a single column")
          end
        end
      end
    end
  end
end
