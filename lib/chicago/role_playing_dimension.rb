require 'chicago/schema/named_element'

module Chicago
  class RolePlayingDimension
    instance_methods.each do |m|
      undef_method m unless m =~ /(^__|^send$|^object_id$)/
    end
    include Schema::NamedElement

    def initialize(name, real_dimension)
      @real_dimension = real_dimension
      super name
      @table_name = :"dimension_#{@name}"
    end

    def table_name
      @real_dimension.table_name.as(@table_name)
    end
    
    def qualify(col)
      col.name.qualify(@table_name)
    end
    
    protected

    def method_missing(name, *args, &block)
      @real_dimension.send name, *args, &block
    end
  end
end
