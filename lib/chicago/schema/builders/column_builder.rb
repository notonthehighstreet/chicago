module Chicago::Schema::Builders
  class ColumnBuilder
    def initialize(defaults={})
      @defaults = defaults
    end
    
    def build(&block)
      @columns = []
      instance_eval(&block) if block_given?
      @columns
    end
    
    def method_missing(type, *args)
      name, rest = args
      @columns << Column.new(name, type, @defaults.merge(rest || {}))
    end
  end
end
