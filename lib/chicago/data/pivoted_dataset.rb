module Chicago
  module Data
    # A data structure that allows you to pivot a Sequel result set.
    #
    # Data often needs to presented in a pivoted fashion, for example
    # instead of presenting data as:
    #
    # | Year | Month | Value |
    # | 2010 | Jan   | 3     |
    # | 2010 | Feb   | 5     |
    # | 2010 | Mar   | 7     |
    #   etc...
    #
    # It is presented as:
    #
    # | Year | Jan | Feb | Mar | etc...
    # | 2010 | 3   | 5   | 7   | etc...
    #   etc...
    #
    # There may need to be multiple pulled up columns.
    #
    # It is assumed that pivoted columns will be on the right hand
    # side of the set of drilldowns - in the example above, Year could
    # not be pivoted by itself.
    class PivotedDataset
      include Enumerable

      # Changes the key that identifies the value for a cell. :value
      # by default.
      attr_accessor :value_key

      # Choose whether to cache the result of the SQL query. The
      # tradeoff is between having a potentially large number of rows
      # in memory or having to run the SQL query multiple times.
      #
      # The choice is necessary, because you don't know the specific 
      # columns that will be returned until the query has been
      # executed, but you will probably need to use the columns in
      # each iteration to avoid the problem of missing values.
      #
      # Defaults to true.
      attr_accessor :cache_sql_result

      # Creates PivotedData given a Sequel dataset. 
      #
      # It assumed that the dataset is ordered such that pivoted values 
      # occur in contiguous blocks. The value of a cell should have the
      # key :value, unless otherwise specified.
      #
      # Options:
      #   :value_key - default is :value, the value cell.
      #   :cache_sql_result - see above.
      def initialize(dataset, pivots, opts={})
        @dataset = dataset
        @pivots = [pivots].flatten
        @value_key = opts[:value_key] || :value
        @rows = nil
        @cache_sql_result = opts[:cache_sql_result].nil?() ? true : opts[:cache_sql_result]
      end

      # Returns an array of rows.
      #
      # Provided for API compatibility with Sequel::Dataset
      def all
        to_a
      end

      # Returns all columns.
      #
      # Provided for API compatibility with Sequel::Dataset
      def columns
        other_columns + pivot_columns
      end

      # Returns all non-pivot columns from the dataset.
      def other_columns
        @dataset.columns - [value_key] - @pivots
      end

      # Returns all pivot columns, unsorted.
      def pivot_columns
        rows.map {|row| row[@pivots.last] }.uniq
      end

      # Iterates over the dataset, yielding rows when the complete set
      # of pivoted columns have been collected.
      #
      # For example, pivoting on month, a dataset that would return
      #
      #    [{:year => 2010, :month => "jan", :value => 1},
      #     {:year => 2010, :month => "feb", :value => 2},
      #     etc...
      #
      # Returns:
      #
      #    [{:year => 2010, "jan" => 1, "feb" => 2},
      #     etc...
      def each
        identifing_components = nil
        pivoted_values = {}

        rows.each do |row| 
          value = row.delete(value_key)
          pivot_keys = @pivots.map {|pivot| row.delete(pivot) }
          if identifing_components != row
            yield identifing_components.merge(pivoted_values) unless identifing_components.nil?
            identifing_components = row
            pivoted_values = pivot_keys.reverse.inject(value) {|v, pivot_key| {pivot_key => v} }
          else
            last_hash = pivoted_values
            pivot_keys[0, pivot_keys.size - 1].each {|key| last_hash = (last_hash[key] ||= {}) }

            last_hash[pivot_keys.last] = value
          end
        end

        yield identifing_components.merge(pivoted_values) unless identifing_components.nil?
      end

      private

      def rows
        if cache_sql_result
          @rows ||= @dataset.all
        else
          @dataset
        end
      end
    end
  end
end
