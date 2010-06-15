module Chicago
  class Fact
    # Returns the name of this fact
    attr_reader :name

    # Returns or sets the database table name for this fact.
    # By default, <name>_facts.
    attr_accessor :table_name

    # Returns an Array of column definitions.
    attr_reader :column_definitions

    # Creates a new fact, named +name+
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

    # Returns a schema hash for use by Sequel::MigrationBuilder,
    # defining all the RDBMS tables needed to store and build this 
    # fact table.
    def db_schema(type_converter)      
      { table_name => {
          :table_options => type_converter.dimension_table_options,
          :columns => column_definitions.map {|c| c.db_schema(type_converter) }
        }
      }
    end

    protected

    def initialize(name)
      @table_name = "#{name}_facts".to_sym
      @name = name.to_sym
      @column_definitions = []
      @identifiers = []
    end
  end
end
