require 'set'

module Chicago
  class BlankSlate
    def self.hide(name)
      undef_method name unless name =~ /^(__|instance_eval)/
    end

    instance_methods.each {|m| hide(m) }
  end

  module Schema
    class HierarchicalElement
      # The name of this element (usually a column or dimension).
      attr_reader :name

      # The implications of this element. If this element is present
      # in whatever context, the others can assumed to be fixed.
      #
      # This is useful for deciding whether we need to group by
      # columns - if we are grouping by the column represented by this
      # element, we don't need to group by any of the implied columns.
      def implications
        @implications.clone
      end

      attr_reader :children

      def initialize(context, name)
        @context = context
        @name = name
        @implications = Set.new
        @children = []
      end

      def implies(*others)
        @implications.merge( others )
      end

      def <=>(*others)
        others = others.map {|name| @context.element(name) }
        @implications.merge(others)
        others.each {|other| other.implies self }.last
      end

      # Not implemented yet. Simply returns other so chains can be
      # defined, but do nothing.
      def >(other)
        other
      end
      
      alias :to_sym :name
    end

    class Hierarchies
      def initialize
        @elements = {}
        @implications = {}
      end

      def element(name)
        @elements[name.to_sym] ||= HierarchicalElement.new(self, name.to_sym)
      end

      def elements
        @elements.values
      end

      # Returns the implications of the named element.
      def implications(name, stop_set=Set.new())
        # TODO: need to revist this algorithm with a clearer mind - it
        # works for simple cycles but am not convinced by either
        # efficiency or correctness in more complicated cases.
        return Set.new if stop_set.include?(name)
        stop_set << name
        i = element(name).implications
        i.inject(i) { |set, element_name| set.merge(implications(element_name, stop_set)) }.to_set
      end
    end

    class HierarchyBuilder < BlankSlate
      attr_reader :__hierarchies

      def initialize(&block)
        @__hierarchies = Hierarchies.new
        instance_eval(&block) if block_given?
      end

      def method_missing(sym, *args)
        @__hierarchies.element(sym)
      end
    end
  end
end
