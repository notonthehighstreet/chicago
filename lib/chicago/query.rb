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
      @implications_used = Set.new
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

      select_columns = column_parts.map do |(name, dimension)|
        measure = @fact.measures.find {|m| m.name == name }

        if measure && measure.semi_additive?
          :avg[name.qualify(@fact.table_name)].as("avg_#{name}".to_sym)
        elsif measure
          :sum[name.qualify(@fact.table_name)].as("sum_#{name}".to_sym)
        elsif dimension
          d = Schema::Dimension[dimension]
          n = name.qualify(d.table_name)

          # imps = d.implications(name).reject {|x| @implications_used.include?(x) }
          # unless imps.empty?
          #   @implications_used << name
          #   @group_removals << lambda { @groups = @groups.reject {|c| 
          #       c.table == d.table_name && 
          #       imps.include?(c.column) } }
          # end

          if d.identifiers.include?(name) && d.original_key
            @group_removals << lambda { @groups = @groups.reject {|(c_name, star_table)| star_table == d && c_name != d.original_key.name } }
            @groups << [d.original_key.name, d]
            n.as(dimension)
          else
            @groups << [name, d]
            n
          end
        else
          n = name.qualify(@fact.table_name)
          @groups << [name, @fact]
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
