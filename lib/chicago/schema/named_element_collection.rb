require 'forwardable'

module Chicago
  module Schema
    # Stores named elements in a Set-like collection.
    #
    # Elements must respond to the method +name+. Elements will be
    # unique across the collection by name, and can be accessed by
    # name. Elements are not ordered.
    #
    # Elements can be added, but not removed from the collection.
    class NamedElementCollection
      include Enumerable
      extend  Forwardable

      # Access an element in the collection by its name.
      def_delegator :@elements, :[]

      # Returns true if there are no elements in this collection.
      def_delegator :@elements, :empty?

      # Returns the number of elements in this collection.
      def_delegator :@elements, :size
      alias :length :size

      # Creates a new collection.
      #
      # Optionally takes a series of named elements.
      def initialize(*args)
        @elements = {}
        args.each {|e| add(e) }
      end

      # Iterate over the elements.
      #
      # @yield element
      def each
        @elements.each {|_,e| yield e }
      end

      # Adds an element to this collection.
      #
      # @return the element just added
      def add(element)
        @elements[element.name] = element
        element
      end
      alias :<< :add

      # Returns true if an element named element.name is in the
      # collection.
      def contain?(element)
        @elements.has_key?(element.name)
      end
      
      # Converts this collection to an array
      #
      # @return [Array]
      def to_a
        @elements.values
      end
    end
  end
end
