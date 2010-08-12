module Chicago
  module ArrayExtensions
    # Removes unecessary array wrapping.
    #
    # For example:
    #
    #    [[[1,2,3]]] # -> [1,2,3]
    #    [[1,2], 3]  # -> [[1,2], 3]
    def condense
      size == 1 && first.kind_of?(Array) ? first.condense : self
    end
  end
end
