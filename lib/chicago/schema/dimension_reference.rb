require 'chicago/schema/column'
require 'forwardable'

module Chicago
  module Schema
    # A reference to a dimension - supports the API of Column and of
    # Dimension, so you can treat it as either.
    class DimensionReference < Column
      extend Forwardable

      def_delegators :@dimension, :columns, :column_definitions, :identifiers, :main_identifier, :identifiable?, :original_key, :natural_key, :table_name, :[], :key_table_name, :countable?
      
      def initialize(name, dimension, opts={})
        super name, :integer, opts.merge(:min => 0)
        @dimension = dimension
        @table_name = "dimension_#{@name}".to_sym
        @key_name   = opts[:key_name] || "#{@name}_dimension_id".to_sym
      end

      def countable_label
        "No. of #{label.pluralize}"
      end
      
      # Returns the key name of this dimension.
      def database_name
        @key_name
      end

      def to_hash
        hsh = super
        hsh[:name] = database_name
        hsh
      end
      
      def qualify(col)
        col.qualify_by(@table_name)
      end

      def qualify_by(table)
        database_name.qualify(table)
      end

      # Returns true if this dimension reference is roleplayed -
      # i.e. it has a different name from the underlying dimension so
      # that, for example, multiple date dimensions can be assigned to
      # the same fact table.
      def roleplayed?
        name != @dimension.name
      end

      # Returns the first null record id for this dimension, or 0 if
      # the dimension has no null records defined.
      def default_value
        record = @dimension.null_records.first
        if record && record[:id]
          record[:id]
        else
          super
        end
      end

      # @private
      def kind_of?(klass)
        klass == Chicago::Schema::Dimension || super
      end
      
      # Dimension references are visitable
      def visit(visitor)
        visitor.visit_dimension_reference(self)
      end
    end
  end
end
