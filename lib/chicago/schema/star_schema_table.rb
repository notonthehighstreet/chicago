module Chicago
  module Schema
    # Base class for both Dimensions and Facts.
    class StarSchemaTable
      extend Definable

      # Returns the name of this dimension or fact.
      attr_reader :name

      # Returns or sets the database table name for this dimension.
      # By default, dimension_<name> or facts_<name>.
      attr_accessor :table_name

      # Returns a schema hash for use by Sequel::MigrationBuilder,
      # defining all the RDBMS tables needed to store and build this 
      # table.
      #
      # Overriden by subclasses.
      def db_schema(type_converter) ; end

      # Defines hierarchies and semantic links between columns, using
      # a HierarchyBuilder.
      #
      # For example:
      #
      #     Dimension.define :date do
      #       ...
      #       hierarchies do
      #         month_number <=> month_name
      #         year.implies decade
      #
      #         year > quarter > month > day
      #       end
      #     end
      def hierarchies(&block)
        @hierarchy = HierarchyBuilder.new(&block).__hierarchies
      end

      # Column implications of the fact or dimension.
      #
      # If one column implies another, it means that the implied
      # column will have a fixed value.
      def implications(name)
        @hierarchy.implications(name).map(&:name)
      end

      protected

      def initialize(name, opts={})
        @name = name.to_sym
        @hierarchy = Hierarchies.new
      end

      # Returns the standard index name for a column / dimension name.
      def index_name(name)
        "#{name}_idx".to_sym
      end

      # Returns a hash defining the main table for the dimension or fact.
      def base_table(type_converter)
        {
          :primary_key => [:id],
          :table_options => type_converter.table_options,
          :indexes => indexes,
          :columns => [{:name => :id, :column_type => :integer, :unsigned => true}] + column_definitions.map {|c| c.db_schema(type_converter) }
        }
      end
    end
  end
end
