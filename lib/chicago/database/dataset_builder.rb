require 'chicago/database/filter'

module Chicago
  module Database
    # Builds a Sequel::Dataset from column definitions, filters etc.
    class DatasetBuilder
      attr_reader :dataset
      
      def initialize(db, query)
        @base_table = query.table
        @query = query
        @dataset = db[query.table.table_name.as(query.table.name)]
        @joined_tables = Set.new
        @selected_columns = []
      end

      def select(columns)
        @selected_columns = columns.flatten
        @dataset = @dataset.
          select(*select_names(columns)).
          group(*group_names(columns))
        add_select_joins_to_dataset(columns)
      end

      def filter(filters)
        filter_columns = Set.new
        filters.each do |filter|
          filter_columns << filter[:column]
          @dataset = Filter.from_hash(filter).filter_dataset(@dataset)
        end
        add_select_joins_to_dataset(filter_columns)
      end

      def order(order)
        columns_to_order = order.map do |c|
          c[:ascending] ? c[:column].to_sym.asc : c[:column].to_sym.desc
        end
        @dataset = @dataset.order(*columns_to_order)
      end

      def limit(limit)
        @dataset = @dataset.limit(limit)
      end
      
      private
      
      def alias_or_sql_name(c)
        @selected_columns.any? {|x| x.column_alias == c.column_alias } ? c.column_alias : c.select_name
      end

      def select_names(columns)
        columns.flatten.map {|c| c.select_name.as(c.column_alias) }
      end

      def group_names(columns)
        columns.flatten.map(&:group_name).compact
      end

      def add_select_joins_to_dataset(columns)
        to_join = columns.flatten.map(&:owner).flatten.uniq.reject {|t| t == @base_table || @joined_tables.include?(t) }
        add_joins_to_dataset(to_join)
      end
      
      def add_joins_to_dataset(to_join)
        @joined_tables.merge(to_join)
        
        unless to_join.empty?
          @dataset = to_join.inject(@dataset) do |dataset, t|
            dataset.join(t.table_name.as(t.name), :id => t.key_name.qualify(@base_table.name))
          end
        end
      end
    end
  end
end
