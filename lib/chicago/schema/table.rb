require 'chicago/schema/named_element'

module Chicago
  module Schema
    # Base class for Dimensions & Facts.
    #
    # @abstract
    # @api public
    class Table
      include NamedElement

      # Returns the database table name for this dimension or fact.
      # By default, dimension_<name> or facts_<name>.
      attr_reader :table_name

      # The uniqueness constraint on the table.
      attr_reader :natural_key

      # Documentation or description for the table.
      attr_reader :description

      # @api private
      def initialize(name, opts={})
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
