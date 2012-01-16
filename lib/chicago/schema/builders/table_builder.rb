module Chicago::Schema::Builders
  class TableBuilder
    # Allows the column builder to be changed when building dimensions
    # & facts.
    attr_writer :column_builder
    
    def initialize(schema)
      @schema = schema
      @column_builder = ColumnBuilder
    end

    def build(klass, name, &block)
      @options[:natural_key] = nil
      instance_eval(&block) if block_given?
      klass.new(name, @options)
    end
    
    protected

    def natural_key(*args)
      @options[:natural_key] = args
    end
  end
end
