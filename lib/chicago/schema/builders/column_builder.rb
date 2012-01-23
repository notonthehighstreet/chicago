require 'chicago/schema/column'

module Chicago::Schema::Builders
  class ColumnBuilder
    def initialize(column_class, defaults={})
      @column_class = column_class
      @defaults = defaults
    end
    
    def build(&block)
      @columns = []
      instance_eval(&block) if block_given?
      @columns
    end
    
    def method_missing(type, *args)
      name, rest = args
      @columns << @column_class.new(name, type, @defaults.merge(rest || {}))
    end
  end
end
