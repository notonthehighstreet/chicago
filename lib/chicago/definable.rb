module Chicago
  # Definable schema classes, such as Sources, Facts & Dimensions.
  #
  # It is expected that other classes will extend this module.
  module Definable
    # Creates a new definition named +name+ and evaluates the block
    # within the context of a new definition.
    #
    # For example:
    #    Dimension.define(:users) do
    #    # ... call instance methods on the Definition
    #    end
    #
    def define(name, opts={}, &block)
      definition = self.new(name, opts)
      definition.instance_eval(&block) if block_given?
      @definitions ||= {}
      @definitions[definition.name] = definition
    end

    # Removes all previously defined objects from the list
    # of known definitions.
    def clear_definitions
      @definitions = {}
    end

    # Returns a list of all defined objects of the extended class's type.
    def definitions
      (@definitions || {}).values
    end
  end
end
