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

      select_columns = column_parts.map do |(name, dimension_name)|
        measure = @fact.measures.find {|m| m.name == name }

        if measure && measure.semi_additive?
          semi_additive_measure_default(name, @fact)
        elsif measure
          additive_measure_default(name, @fact)
        elsif dimension_name
          dimension = Schema::Dimension[dimension_name]

          if dimension.identifiers.include?(name) && dimension.original_key
            @group_removals << lambda { @groups = @groups.reject {|(c_name, star_table)| star_table == dimension && c_name != dimension.original_key.name } }
            @groups << [dimension.original_key.name, dimension]
          else
            @groups << [name, dimension]
          end

          dimension_default(name, dimension)
        else
          @groups << [name, @fact]
          degenerate_dimension_default(name, @fact)
        end
      end

      @dataset = @dataset.select_more(*select_columns)
      add_joins_and_groups Set.new(column_parts.map(&:last).compact.map {|d| Schema::Dimension[d] })
      self
    end

    private

    def additive_measure_default(name, fact)
      :sum[name.qualify(fact.table_name)].as("sum_#{name}".to_sym)
    end

    def semi_additive_measure_default(name, fact)
      :avg[name.qualify(fact.table_name)].as("avg_#{name}".to_sym)
    end

    def degenerate_dimension_default(name, fact)
      name.qualify(@fact.table_name)
    end

    def dimension_default(name, dimension)
      if dimension.identifiers.include?(name) && dimension.original_key
        name.qualify(dimension.table_name).as(dimension.name)
      else
        name.qualify(dimension.table_name)
      end
    end

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
      @groups = fixup_groups(@groups)
      unless @groups.empty?
        cols = @groups.map {|(name, star_table)| name.qualify(star_table.table_name) }
        @dataset = @dataset.group(*cols)
      end
    end

    def fixup_groups(groups)
      return_groups = []
      until groups.empty?
        return_groups << groups.shift
        g_name, star_table = return_groups.last
        imps = star_table.implications(g_name)
        groups.reject! {|(n, s)| s == star_table && imps.include?(n) }
      end
      return_groups
    end
  end
end
