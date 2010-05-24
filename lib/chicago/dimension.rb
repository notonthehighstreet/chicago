module Chicago
  class Dimension
    # Returns the name of this dimension
    attr_reader :name

    # Returns or sets the database table name for this dimension.
    # By default, <name>_dimension.
    attr_accessor :table_name
    
    # Returns an Array of column definitions.
    attr_reader :column_definitions

    # Creates a new dimension, named +name+
    def self.define(name, &block)
      dimension = self.new(name)
      dimension.instance_eval(&block) if block_given?
      dimension
    end

    # Define a set of columns for this dimension. See ColumnGroupBuilder
    # for details.
    def columns(&block)
      @column_definitions += Schema::ColumnGroupBuilder.new(&block).column_definitions
    end

    protected

    def initialize(name)
      @table_name = "#{name}_dimension".to_sym
      @name = name.to_sym
      @column_definitions = []
    end
  end
end
