# Classes that implement the Schema definition DSL.
#
# Builders generally take a block which is evaluated in its context,
# and protected methods on the builder define the DSL.
module Chicago::Schema::Builders
  # @abstract
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

    def description(str)
      @options[:description] = str
    end
    
    def natural_key(*args)
      @options[:natural_key] = args
    end
  end
end
