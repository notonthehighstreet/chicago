module Chicago
  class DimensionDefinition
    # Returns the name of this dimension
    attr_reader :name

    # Returns or sets the database table name for this dimension.
    # By default, <name>_dimension.
    attr_accessor :table_name
    
    # Creates a new dimension, named +name+
    def initialize(name)
      @table_name = "#{name}_dimension".to_sym
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

    # Defines a column with the type of the method name, named +name+.
    def method_missing(type, *args)
      name, rest = args
      define_column(:type => type, :name => name)
    end
  end
end
