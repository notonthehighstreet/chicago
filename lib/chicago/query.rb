require 'set'
require 'chicago/database/dataset_builder'
require 'chicago/schema/column_parser'

module Chicago
  # A query object, wrapping a raw AST and linked to a schema.
  #
  # The raw AST looks like the following:
  #
  #     {
  #       :table_name => "name",
  #       :query_type => "fact",
  #       :columns => [... column definitions ...],
  #       :filters => [... filter definitions ...],
  #       :order => [... order definitions ...] 
  #     }
  #
  # @api public
  class Query
    # Returns an the fact or dimension this query is based on.
    attr_reader :table

    # Returns an array of Columns selected in this query.
    attr_reader :columns

    class << self
      # Sets the default Sequel::Database used by queries.
      attr_accessor :default_db

      # Sets the column parser class to be used.
      #
      # By default Schema::ColumnParser
      attr_accessor :column_parser
    end
    self.column_parser = Schema::ColumnParser

    # Creates a query over a schema from a raw query AST.
    #
    # @api public
    def initialize(schema, ast)
      @table_name = (ast[:table_name] || ast["table_name"]).to_sym
      @query_type = (ast[:query_type] || ast["query_type"]).to_sym
      @columns = []
      @filters = []
      @order = []
      @table = schema.send(@query_type, @table_name) or
        raise MissingDefinitionError.new("#{@query_type} '#{@table_name}' is not in the schema")
      @column_parser = Schema::ColumnParser.new(schema)

      select(*(ast[:columns] || ast["columns"]) || [])
      filter(*(ast[:filters] || ast["filters"]) || [])
      order(*(ast[:order] || ast["order"]) || [])
    end

    # @api public
    def select(*columns)
      @columns += columns.map {|c| @column_parser.parse(c) }
      self
    end

    # @api public
    def filter(*filters)
      copied_filters = filters.dup
      copied_filters.each do |filter|
        filter[:column] = @column_parser.parse(filter[:column]).first
      end
      @filters += copied_filters
      self
    end

    # Order the results by the specified columns.
    # 
    # @param ordering an array of hashes, of the form {:column =>
    #   "name", :ascending => true}
    # @api public
    def order(*ordering)
      @order = ordering.map do |c|
        if c.kind_of?(String)
          {:column => @column_parser.parse(c).first, :ascending => true}
        else
          {:column => @column_parser.parse(c[:column]).first,
            :ascending => c[:ascending]}
        end
      end
      self
    end
    
    # Applies the query to a Sequel::Database and returns a
    # Sequel::Dataset.
    #
    # @api public
    def dataset(db=nil)
      db ||= self.class.default_db
      builder = Database::DatasetBuilder.new(db, self)
      builder.select(@columns)
      builder.filter(@filters)
      builder.order(@order)
      builder.dataset
    end
  end
end
