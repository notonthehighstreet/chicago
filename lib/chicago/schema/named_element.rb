module Chicago
  module Schema
    module NamedElement
      # Returns the name of this dimension or fact.
      attr_reader :name
      
      # Returns a human-friendly name for this dimension or fact.
      attr_reader :label
      
      def initialize(name, opts={})
        @name = name.to_sym
        @label = opts[:label] || name.to_s.titlecase
      end
    end
  end
end
