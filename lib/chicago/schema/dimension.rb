module Chicago
  module Schema

  class Dimension < StarSchemaTable
    # Returns an Array of possible identifying columns for this dimension.
    attr_reader :identifiers

    # Returns an Array of column definitions.
    attr_reader :column_definitions

    # Defines a dimension.
    #
    # :name - the name of the dimension
    # 
    # Options:
    #
    # :conforms_to - the name of the dimension this dimension conforms
    # to. This dimension must already be defined.
    # :block - evaluated on an instance of dimension. Use this to
    # define columns etc.
    def self.define(name, opts={}, &block)
      @definitions ||= {}
      if opts[:conforms_to] && @definitions[opts[:conforms_to]].nil?
        raise "Dimension #{opts[:conforms_to]} has not been defined" 
      end
      super
    end

    # Define a set of columns for this dimension or fact. See
    # ColumnGroupBuilder for details.
    #
    # A conformed dimension may just reference the names of the
    # columns that it uses from its 'parent' dimension.
    #
    # For example:
    #
    #    Chicago::Dimension.define(:date) do
    #      columns do
    #        date   :date
    #        year   :year
    #        string :month
    #        ...
    #      end
    #    end
    #
    #    Chicago::Dimension.define(:month, :conforms_to => :date) do
    #      columns :year, :month
    #    end
    #
    def columns(*names, &block)
      if @conforms_to
        columns = self.class.definitions.find {|dimension| dimension.name == @conforms_to }.column_definitions
        definitions = columns.select {|c| names.include?(c.name) }
        raise "Extra non-conforming columns detected" if definitions.size != names.size
        @column_definitions += definitions
      else
        @column_definitions += ColumnGroupBuilder.new(&block).column_definitions
      end
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

    # Returns the schema for this dimension.
    # 
    # This includes the base table, and a key mapping table if
    # a column named :original_id is present.
    def db_schema(type_converter)      
      @tables = {}
      @tables[table_name] = base_table(type_converter)
      @tables[key_table_name] = key_table(original_key, type_converter) if original_key
      @tables
    end
      
    protected
    
    # Use Dimension.define rather than constructing a Dimension manually.
    def initialize(name, opts={})
      super
      @conforms_to = opts[:conforms_to]
      @identifiers = []
      @column_definitions = []
      @table_name = "#{name}_dimension".to_sym
    end

    private

    def base_table(type_converter)
      {
        :primary_key => :id,
        :table_options => type_converter.table_options,
        :indexes => indexes,
        :columns => [{:name => :id, :column_type => :integer, :unsigned => true}] + column_definitions.map {|c| c.db_schema(type_converter) }
      }
    end

    def key_table(original_id, type_converter)
      {
        :primary_key => [:original_id, :dimension_id],
        :columns => [original_id.db_schema(type_converter),
                     {:name => :dimension_id, :column_type => :integer, :unsigned => true, :null => false}]
      }
    end

    def original_key
      @original_key ||= @column_definitions.find {|c| c.name == :original_id }
    end

    def key_table_name
      "#{table_name}_keys".to_sym
    end

    def indexes
      @column_definitions.reject {|c| c.descriptive? }.inject({}) do |idx, column|
        idx[index_name(column.name)] = {:columns => column.name}
        idx
      end
    end
  end
end
end
