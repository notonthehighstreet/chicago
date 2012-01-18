require 'chicago/errors'
require 'chicago/column'
require 'chicago/measure'
require 'chicago/dimension_reference'
require 'chicago/degenerate_dimension'
require 'chicago/dimension'
require 'chicago/fact'
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
    #
    # Modifying the elements of this array will not mutate the schema.
    def facts
      @facts.dup
    end

    # Returns an Array of dimensions in this schema.
    #
    # Modifying the elements of this array will not mutate the schema.
    def dimensions
      @dimensions.dup
    end

    # Adds a prebuilt schema table to the schema
    #
    # Schema tables may not be dupliates by name.
    #
    # TODO: figure out how to deal with linked dimensions when adding
    # facts.
    def add(schema_table)
      if schema_table.kind_of? Fact
        collection = @facts
      elsif schema_table.kind_of? Dimension
        collection = @dimensions
      end
      
      if collection.any? {|t| t.name == schema_table.name }
        raise DuplicateTableError.new("#{schema_table.class} '#{schema_table.name}' has already been defined.")
      end

      collection << schema_table
    end

    # @raises Chicago::MissingDefinitionError
    def define_fact(name, &block)
      add Schema::Builders::FactBuilder.new(self).build(name, &block)
      @facts.last
    end

    def define_dimension(name, &block)
      add Schema::Builders::DimensionBuilder.new(self).build(name, &block)
      @dimensions.last
    end

    # @raises Chicago::MissingDefinitionError
    def define_shrunken_dimension(name, base_name, &block)
      add Schema::Builders::ShrunkenDimensionBuilder.new(self, base_name).
        build(name, &block)
      @dimensions.last
    end
  end
end
