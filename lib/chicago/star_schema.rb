require 'chicago/errors'
require 'chicago/schema/column'
require 'chicago/schema/measure'
require 'chicago/schema/dimension_reference'
require 'chicago/schema/dimension'
require 'chicago/schema/fact'
require 'chicago/schema/builders/fact_builder'
require 'chicago/schema/builders/dimension_builder'
require 'chicago/schema/builders/shrunken_dimension_builder'
require 'chicago/schema/builders/column_builder'

module Chicago
  # A collection of facts & dimensions.
  class StarSchema
    def initialize
      @dimensions = []
      @facts = []
    end

    # Returns an Array of facts in this schema.
    def facts
      @facts.dup
    end

    # Returns an Array of dimensions in this schema.
    def dimensions
      @dimensions.dup
    end

    def fact(name)
      @facts.detect {|f| f.name == name }
    end

    def dimension(name)
      @dimensions.detect {|d| d.name == name }
    end
    
    # Returns an Array of all dimensions and facts in this schema.
    def tables
      @dimensions + @facts
    end
    
    # Adds a prebuilt schema table to the schema
    #
    # Schema tables may not be dupliates of already present tables in
    # the schema.
    #
    # TODO: figure out how to deal with linked dimensions when adding
    # facts.
    def add(schema_table)
      if schema_table.kind_of? Schema::Fact
        collection = @facts
      elsif schema_table.kind_of? Schema::Dimension
        collection = @dimensions
      end
      
      if collection.any? {|t| t.name == schema_table.name }
        raise DuplicateTableError.new("#{schema_table.class} '#{schema_table.name}' has already been defined.")
      end

      collection << schema_table
    end

    # Defines a fact table named 'name' in this schema.
    #
    # See Chicago::Schema::Fact and Chicago::Schema::Builders::FactBuilder for
    # details of the DSL.
    #
    # @raises Chicago::MissingDefinitionError
    def define_fact(name, &block)
      add Schema::Builders::FactBuilder.new(self).build(name, &block)
      @facts.last
    end

    # Defines a dimension table named 'name' in this schema.
    #
    # See Chicago::Schema::Dimension and
    # Chicago::Schema::Builders::DimensionBuilder for details of the
    # DSL.
    #
    # For example:
    #
    #    @schema.define_dimension(:date) do
    #      columns do
    #        date   :date
    #        year   :year
    #        string :month
    #        ...
    #      end
    #
    #      natural_key :date
    #      null_record :id => 1, :month => "Unknown Month"
    #    end
    #
    def define_dimension(name, &block)
      add Schema::Builders::DimensionBuilder.new(self).build(name, &block)
      @dimensions.last
    end

    # Defines a shrunken dimension table named 'name' in this schema.
    #
    # base_name is the name of the base dimension that the shrunken
    # dimension is derived from; this base dimention must already be
    # defined.
    #
    # See Chicago::ShrunkenDimension and
    # Chicago::Schema::Builders::ShrunkenDimensionBuilder for details
    # of the DSL.
    #
    # @raises Chicago::MissingDefinitionError
    def define_shrunken_dimension(name, base_name, &block)
      add Schema::Builders::ShrunkenDimensionBuilder.new(self, base_name).
        build(name, &block)
      @dimensions.last
    end
  end
end
