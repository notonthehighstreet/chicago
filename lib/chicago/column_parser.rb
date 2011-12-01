module Chicago
  class ColumnParser
    def parse_column(context, str)
      column_name, table_name, op_name = split_input_string(str)
      column = find_column(context, table_name, column_name)
      
      unless column
        raise Chicago::Schema::InvalidColumnError.new("#{table_name} does not have a column #{column_name}")
      end
      
      if op_name
        Chicago::Schema::CalculatedColumn.new(column, op_name)
      else
        column
      end
    end
    
    def split_input_string(str)
      column_name, table_name, op_name = str.split('.').reverse.map(&:to_sym)
      
      if table_name.nil?
        table_name = column_name
        column_name = nil
      end
      
      [column_name, table_name, op_name]
    end
    
    def find_column(context, table_name, column_name)
      if table_name == context.name
        context[column_name]
      elsif ! context.dimension_names.include?(table_name)
        raise Chicago::Schema::InvalidDimensionError.new("#{context.label} does not have a dimension #{table_name}")
      elsif column_name
        context.dimension_definitions[table_name][column_name]
      else
        d = Chicago::Schema::Dimension[table_name]
        Chicago::Schema::DimensionAsColumn.new(d[d.main_identifier])
      end
    end
  end
end
