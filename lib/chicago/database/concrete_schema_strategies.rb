module Chicago
  module Database
    # Generic database strategy.
    #
    # This supplements Sequel's type conversion strategy rather than
    # replaces it, so +:boolean+ will still return +:boolean+ rather
    # than +tinyint(1)+ in the case of mysql.
    class ConcreteSchemaStrategy
      # Factory method that returns an appropriate type conversion
      # stratgey for the given database.
      #
      # If a database-specific strategy cannot be found, returns a
      # generic strategy.
      #
      # @return [ConcreteSchemaStrategy]
      def self.for_db(db)
        if db.database_type == :mysql
          MysqlStrategy.new
        elsif db.database_type == :postgres && 
            db.opts[:adapter] == "redshift"
          RedshiftStrategy.new
        else
          self.new
        end
      end

      # Returns the definition of the column which should be used as
      # the primary id column.
      def id_column
        {
          :name => :id,
          :column_type => :integer,
          :unsigned => true
        }
      end

      # Returns options to be passed to the Migration Builder.
      #
      # Empty by default, may be overridden by subclasses for specific
      # databases.
      def migration_options
        {}
      end

      # Returns the hash of the column.
      def column_hash(column)
        hsh = column.to_hash.merge(:column_type => db_type(column))
        hsh.delete(:elements) if hsh.has_key?(:elements)
        hsh
      end

      # Returns the indexes for the given table.
      def indexes(table)
        IndexGenerator.new(table).indexes
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
        if min && max && in_numeric_range?(min, max, SMALL_INT_MAX)
          :smallint
        else
          :integer
        end
      end

      protected

      def in_numeric_range?(min, max, unsigned_limit)
        in_signed_limit?(min, max, unsigned_limit) || 
          (min >= 0 && max <= unsigned_limit)
      end

      def in_signed_limit?(min, max, unsigned_limit)
        signed_limit = (unsigned_limit + 1) / 2
        (min >= -signed_limit && max <= signed_limit - 1)
      end
    end

    # Redshift-specific database schema strategy
    class RedshiftStrategy < ConcreteSchemaStrategy
      def migration_options
        {:separate_alter_table_statements => true, :immutable_columns => true}
      end

      def id_column
        {
          :name => :id,
          :column_type => :integer,
          :unsigned => false
        }
      end

      def column_hash(column)
        hsh = super(column)
        hsh.delete(:unsigned)
        if column.column_type == :string && hsh[:size]
          # Redshift column sizes are in bytes, not characters, so
          # increase to 4 bytes per-char for UTF-8 reasons.
          hsh[:size] *= 4
        end

        hsh
      end

      def db_type(column)
        t = super(column)

        case t
        when :year then :smallint
        when :binary then :varchar
        else
          t
        end
      end

      # Redshift does not support indexes, so do not output any.
      def indexes(table)
        []
      end

      # Redshift does not support unsigned Integers
      def in_numeric_range?(min, max, unsigned_limit)
        in_signed_limit?(min, max, unsigned_limit)
      end
    end

    # MySql-specific database schema strategy
    class MysqlStrategy < ConcreteSchemaStrategy
      def column_hash(column)
        column.to_hash.merge :column_type => db_type(column)
      end

      def db_type(column)
        return :enum if column.elements && column.elements.size < 65_536
        super(column)
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
    end
  end
end

