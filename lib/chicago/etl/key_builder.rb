require 'thread'
require 'digest/md5'

module Chicago
  module ETL
    KEY_TABLE_FORMAT = "keys_%s".freeze
    
    # Builds a surrogate key for a dimension record, without relying
    # on the database's AUTO_INCREMENT functionality.
    class KeyBuilder
      # The name of the key table.
      attr_reader :key_table
      
      def initialize(dimension, db)
        @mutex = Mutex.new
        @cache_loaded = false
        @db = db
        @dimension = dimension
        @key_table = sprintf(KEY_TABLE_FORMAT, dimension.table_name).to_sym
        @new_keys = []
      end

      # Returns an appropriate key builder for the dimension, using
      # the staging database for key management.
      def self.for_dimension(dimension, staging_db)
        if dimension.identifiable?
          IdentifiableDimensionKeyBuilder.new(dimension, staging_db)
        else
          HashingKeyBuilder.new(dimension, staging_db)
        end
      end

      # Returns a surrogate key, given a record row.
      #
      # @raises Chicago::ETL::KeyError if the surrogate key cannot be
      #   determined from the row data.
      def key(row)
        fetch_cache unless cache_loaded?
        row_id = original_key(row)
        new_key = @key_mapping[row_id]
        
        if new_key
          new_key
        else
          new_key = increment_key
          @new_keys << {:original_id => key_for_insert(row_id), :dimension_id => new_key}
          @key_mapping[row_id] = new_key
        end
      end

      # Returns the original key for the row.
      #
      # Overridden by subclasses.
      def original_key(row)
      end

      # Flushes any newly created keys to the key table.
      def flush
        @db[key_table].multi_insert(@new_keys)
        @new_keys.clear
      end
      
      protected
      
      def increment_key
        @mutex.synchronize do
          @i += 1
        end
      end

      def fetch_cache
        @key_mapping = @db[key_table].
          select_hash(original_key_select_fragment, :dimension_id)
        @i = @db[key_table].max(:dimension_id) || 0
        @cache_loaded = true
      end

      def cache_loaded?
        @cache_loaded
      end
    end

    # Key builder for identifiable dimensions.
    #
    # This should not be instantiated directly, use
    # KeyBuilder.for_dimension.
    class IdentifiableDimensionKeyBuilder < KeyBuilder
      def key(row)
        raise KeyError.new("Row does not have an original_id field") unless row.has_key?(:original_id)
        super
      end

      def original_key(row)
        row[:original_id]
      end

      def key_for_insert(original_id)
        original_id
      end

      def original_key_select_fragment
        :original_id
      end
    end

    # Key builder for dimensions with natuaral keys, but no simple
    # key.
    #
    # This should not be instantiated directly, use
    # KeyBuilder.for_dimension.
    class HashingKeyBuilder < KeyBuilder
      def original_key(row)
        columns = if @dimension.natural_key.nil?
                    @dimension.columns.map(&:name)
                  else
                    @dimension.natural_key
                  end
        
        str = columns.map {|column| row[column].to_s.upcase }.join
        Digest::MD5.hexdigest(str).upcase
      end

      def key_for_insert(original_id)
        ("0x" + original_id).lit
      end

      def original_key_select_fragment
        :hex.sql_function(:original_id).as(:original_id)
      end
    end
  end
end
