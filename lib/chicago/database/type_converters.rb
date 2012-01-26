module Chicago
  module Database
    module TypeConverters
      # Generic type conversion strategy.
      #
      # This supplements Sequel's type conversion strategy rather than
      # replaces it, so +:boolean+ will still return +:boolean+ rather
      # than +tinyint(1)+ in the case of mysql.
      class DbTypeConverter
        # Factory method that returns an appropriate type conversion
        # stratgey for the given database.
        #
        # If a database-specific strategy cannot be found, returns a
        # generic strategy.
        #
        # @return [DbTypeConverter]
        def self.for_db(db)
          return MysqlTypeConverter.new if db.database_type == :mysql
          self.new
        end

        # Returns a db type given a column definition
        #
        # @return [Symbol]
        def db_type(column)
          case column.column_type
          when :integer then integer_type(column.min, column.max)
          when :string  then string_type(column.min, column.max)
          when :money   then :decimal
          when :percent then :decimal
          else
            column.column_type
          end
        end

        # Returns sequel table options for a dimension or fact table.
        #
        # None by default, but database-specific subclasses may
        # override this.
        #
        # @return [Hash]
        def table_options
          {}
        end

        # Returns a database type for a string column.
        #
        # @return [Symbol]
        def string_type(min, max)
          min && max && min == max ? :char : :varchar 
        end
            
        # Returns a database integer column type, big enough to fit
        # values between min and max, or integer if a specific type
        # cannot be found.
        #
        # @return [Symbol]
        # @raise an ArgumentError if min or max is too large for a
        #   single database column.
        def integer_type(min, max)
          signed_limit = (SMALL_INT_MAX + 1) / 2
          if min && max && ((min >= -signed_limit && max <= signed_limit - 1) || (min >= 0 && max <= SMALL_INT_MAX))
            :smallint
          else
            :integer
          end
        end
      end

      # MySql-specific type conversion strategy
      class MysqlTypeConverter < DbTypeConverter
        def db_type(column)
          return :enum if column.elements && column.elements.size < 65_536
          super
        end

        # Returns table options for a dimension or fact table.
        #
        # Dimension tables are defined as MyISAM tables in MySQL.
        def table_options
          {:engine => "myisam"}
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
