module Chicago
  # Base class for both Dimensions and Facts.
  class StarSchemaTable
    # Returns the name of this dimension
    attr_reader :name

    # Returns or sets the database table name for this dimension.
    # By default, <name>_dimension.
    attr_accessor :table_name
    
    # Returns an Array of column definitions.
    attr_reader :column_definitions
    
    # Creates a new dimension or fact named +name+
    #
    # This should be called on subclasses - i.e. Dimension.define or
    # Fact.define, not this class.
    def self.define(name, &block)
      definition = self.new(name)
      definition.instance_eval(&block) if block_given?
      definition
    end

    # Define a set of columns for this dimension or fact. See
    # ColumnGroupBuilder for details.
    def columns(&block)
      @column_definitions += Schema::ColumnGroupBuilder.new(&block).column_definitions
    end


    # Returns a schema hash for use by Sequel::MigrationBuilder,
    # defining all the RDBMS tables needed to store and build this 
    # table.
    #
    # Overriden by subclasses.
    def db_schema(type_converter) ; end

    protected

    def initialize(name)
      @name = name.to_sym
      @column_definitions = []
      @identifiers = []
    end
  end
end
