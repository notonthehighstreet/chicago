require 'set'

module Chicago
  class Query
    attr_reader :dataset

    def initialize(db, fact)
      @fact = Schema::Fact[fact]
      @dataset = db[@fact.table_name]
      @joins = Set.new
      @groups = []
      @group_removals = []
    end

    def columns(*cols)
      column_parts = cols.map do |name|
        name, dimension = name.to_s.split('.').reverse.map(&:to_sym)

        if @fact.dimension_names.include?(name)
          dimension = name
          name = Schema::Dimension[name].main_identifier
        end

        [name, dimension]
      end

      select_columns = column_parts.map do |name, dimension|
        measure = @fact.measures.find {|m| m.name == name }

        if measure && measure.semi_additive?
          :avg[name.qualify(@fact.table_name)].as("avg_#{name}".to_sym)
        elsif measure
          :sum[name.qualify(@fact.table_name)].as("sum_#{name}".to_sym)
        elsif dimension
          d = Schema::Dimension[dimension]
          n = name.qualify(d.table_name)
          if d.identifiers.include?(name) && d.original_key
            @groups << d.original_key.name.qualify(d.table_name)
            @group_removals << lambda { @groups = @groups.reject {|c| c.table == d.table_name && c.column != d.original_key.name } }
            n.as(dimension)
          else
            @groups << n
            n
          end
        else
          n = name.qualify(@fact.table_name)
          @groups << n
          n
        end
      end

      @dataset = @dataset.select_more(*select_columns)
      add_joins_and_groups Set.new(column_parts.map(&:last).compact.map {|d| Schema::Dimension[d] })
      self
    end

    private

    def add_joins_and_groups(dimensions)
      to_join = dimensions - @joins
      @joins = @joins.merge(to_join)
      unless to_join.empty?
        @dataset = @joins.inject(@dataset) do |dataset, d|
          dataset.join(d.table_name, 
                       :id => @fact.dimension_key(d.name).qualify(@fact.table_name))
        end
      end

      @group_removals.each {|r| r.call }
      unless @groups.empty?
        @dataset = @dataset.group(*@groups)
      end
    end
  end
end
