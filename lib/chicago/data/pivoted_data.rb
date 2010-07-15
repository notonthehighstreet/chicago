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
    # There may need to be multiple facts pulled up as columns.
    #
    # It is assumed that pivoted columns will be on the right hand
    # side of the set of drilldowns - in the example above, Year could
    # not be pivoted by itself.
    class PivotedData
      include Enumerable

      # Creates PivotedData given a Sequel dataset (or something that
      # responds to #each and yields hashes). It assumed that the
      # dataset is ordered such that pivoted values occur in
      # contiguous blocks. The value of a cell should have the key :value.
      def initialize(dataset, pivot_on)
        @dataset = dataset
        @pivot_on = pivot_on
      end

      def each
        identifing_components = nil
        pivoted_values = {}

        @dataset.each do |row| 
          value = row.delete(:value)
          pivot_key = row.delete(@pivot_on)

          if identifing_components != row
            yield identifing_components.merge(pivoted_values) unless identifing_components.nil?
            identifing_components = row
            pivoted_values = {pivot_key => value}
          else
            pivoted_values[pivot_key] = value
          end
        end

        yield identifing_components.merge(pivoted_values) unless identifing_components.nil?
      end
    end
  end
end
