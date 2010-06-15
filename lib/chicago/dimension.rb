module Chicago
  class Dimension
    # Returns the name of this dimension
    attr_reader :name

    # Returns or sets the database table name for this dimension.
    # By default, <name>_dimension.
    attr_accessor :table_name
    
    # Returns an Array of column definitions.
    attr_reader :column_definitions

    # Returns an Array of possible identifying columns for this dimension.
    attr_reader :identifiers

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

    # Returns the user-friendly identifier for this record.
    def main_identifier
      @identifiers.first
    end

    # Defines one or more human-readable identifiers for this
    # dimension record.
    #
    # There is no expectation that this value will be unique, but it
    # is intended to identify a single record in a user friendly way.
    #
    # Additional identifiers are specified using :and => [:id1,
    # :id2...]
    #
    # Example, a customer might be:
    #
    #    identified_by :full_name, :and => [:email]
    def identified_by(main_id, opts={:and => []})
      @identifiers = [main_id] + opts[:and]
    end

    # Returns a schema hash for use by Sequel::MigrationBuilder,
    # defining all the RDBMS tables needed to store and build this 
    # dimension.
    def db_schema(db)
      { table_name => {
          :primary_key => :id,
          :columns => [{:name => :id, :column_type => :integer, :unsigned => true}] + column_definitions.map {|c| c.db_schema(db) }
        }
      }
    end
      
    protected

    def initialize(name)
      @table_name = "#{name}_dimension".to_sym
      @name = name.to_sym
      @column_definitions = []
      @identifiers = []
    end
  end
end
