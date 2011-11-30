require 'set'

module Chicago
  # A query interface to the star schema, similar in interface to a Sequel
  # dataset.
  #
  # A query object allows a simplified version of SQL, which leverages
  # the metadata provided by the Dimension, Fact & Column definitions
  # so that sensible defaults can be applied, and explicit joins
  # can be avoided.
  class Query
    attr_reader :dataset

    # Creates a new query for a Fact table.
    def self.fact(db, fact_name)
      new(db, Schema::Fact[fact_name])
    end
    
    # Creates a new Query object, given a database connection and a
    # schema model.
    #
    # FIXME: non-fact models will currently break.
    def initialize(db, schema_model)
      @fact = schema_model
      @dataset = db[@fact.table_name]
      @joins = Set.new
      @groups = []
      @group_removals = []
      @columns = []
    end

    # Selects columns, generating the appropriate sql column references
    # in the built dataset.
    #
    # select may be called multiple times.
    #
    # Returns the same query object.
    def select(*cols)
      select_columns = column_parts(cols).map do |(name, dimension_name)|
        measure = @fact.measures.find {|m| m.name == name }

        if measure && measure.semi_additive?
          @columns << @fact[name]
          semi_additive_measure_default(name, @fact)
        elsif measure
          @columns << @fact[name]
          additive_measure_default(name, @fact)
        elsif dimension_name
          dimension = Schema::Dimension[dimension_name]
          if name == dimension.main_identifier
            @columns << Schema::DimensionAsColumn.new(dimension[name])
          else
            @columns << dimension[name]
          end
          add_dimension_column_to_grouping(name, dimension)
          dimension_default(name, dimension)
        else
          @groups << [name, @fact]
          @columns << @fact[name]
          degenerate_dimension_default(name, @fact)
        end
      end

      @dataset = @dataset.select_more(*select_columns)
      add_joins_and_groups Set.new(column_parts(cols).map(&:last).compact.map {|d| Schema::Dimension[d] })
      self
    end

    # Returns an array of Columns selected in this query.
    def columns
      @columns
    end
    
    def order(*cols)
      order_columns = column_parts(cols).map do |(name, dimension_name)|
        if dimension_name
          name.qualify(Schema::Dimension[dimension_name].table_name)
        else
          name.qualify(@fact.table_name)
        end
      end
      @dataset = @dataset.order(*order_columns)
      self
    end
    
    private

    def add_dimension_column_to_grouping(name, dimension)
      if dimension.identifiers.include?(name) && dimension.original_key
        @group_removals << lambda { @groups = @groups.reject {|(c_name, star_table)| star_table == dimension && c_name != dimension.original_key.name } }
        @groups << [dimension.original_key.name, dimension]
      else
        @groups << [name, dimension]
      end
    end
    
    def column_parts(cols)
      cols.map do |name|
        name, dimension = name.to_s.split('.').reverse.map(&:to_sym)

        if @fact.dimension_names.include?(name)
          dimension = name
          name = Schema::Dimension[name].main_identifier
        end

        [name, dimension]
      end
    end

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
