module Chicago
  class DimensionDefinition
    # Returns the name of this dimension
    attr_reader :name

    # Creates a new dimension, named +name+
    def initialize(name)
      @name = name.to_sym
      @column_definitions = []
    end

    # Defines a new column on this dimension.
    def define_column(definition)
      if definition.kind_of? Hash
        @column_definitions << ColumnDefinition.new(definition)
      else
        @column_definitions << definition
      end
    end

    # Returns an Array of ColumnDefinitions.
    def column_definitions
      @column_definitions.clone
    end

    def varchar(name)
      define_column(:type => :varchar, :name => name)
    end
  end
end
