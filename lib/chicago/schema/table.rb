require 'chicago/schema/named_element'

module Chicago
  module Schema
    # Abstract base class for Dimensions & Facts.
    class Table
      include NamedElement

      # Returns or sets the database table name for this dimension or
      # fact.  By default, dimension_<name> or facts_<name>.
      attr_reader :table_name

      # The uniqueness constraint on the table.
      attr_reader :natural_key

      # Documentation or description for the table.
      attr_reader :description
      
      def initialize(name, opts={}) #::nodoc::
        super
        @natural_key = opts[:natural_key]
        @description = opts[:description]
      end
    
      # Returns the name of the column, qualified by this schema
      # table. This is a Sequel::SQL::QualifiedIdentifier.
      def qualify(col)
        col.name.qualify(table_name)
      end
      
      # Returns the column named 'name'.
      def [](name)
        columns.detect {|c| c.name == name }
      end
    end
  end
end
