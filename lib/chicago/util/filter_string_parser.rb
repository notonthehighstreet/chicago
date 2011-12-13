require 'strscan'
require 'set'

module Chicago
  # Evaluates a filter string to a set of sequel dataset filter calls.
  # Useful for dealing with filters serialised in urls etc.
  #
  # Can only currently cope with simple equality and AND conditions.
  #
  # The string format is:
  #
  #     dimension.field:value,value,...;dimension.field:value...
  class FilterStringParser
    # Returns a set of dimensions that have been filtered.
    attr_reader :dimensions

    def initialize(string, context=nil)
      @original_string = string
      @filters = []
      @dimensions = Set.new
      @context = context
      parse
    end

    def apply_to(dataset)
      @filters.inject(dataset) {|dataset, filter| dataset.filter(filter) }
    end

    def parse
      scanner = StringScanner.new(@original_string)
      until scanner.eos?
        scanner.scan(/([a-zA-Z_0-9]+)(?:\.([a-zA-Z_0-9]+))?:/) or raise "Missing valid filter dimension/field"
        
        dimension = scanner[1].to_sym
        field     = scanner[2] ? scanner[2].to_sym : :original_id
        
        @dimensions << dimension
        scanner.scan(/[^;]+/) or raise "Missing Value"
        
        values = scanner[0].split(",")
        value = values.size == 1 ? values.first : values
        if @context && dimension == @context.name
          @filters << {field.qualify(@context.table_name) => value}
        else
          @filters << {field.qualify("dimension_#{dimension}".to_sym) => value}
        end
        scanner.skip(/;/)
      end
    end
  end
end
