module Chicago
  module ArrayExtensions
    # Removes unecessary array wrapping.
    #
    # For example:
    #
    #    [[[1,2,3]]] # -> [1,2,3]
    #    [[1,2], 3]  # -> [[1,2], 3]
    #
    # @todo remove once PivotedDataset has been removed.
    def condense
      size == 1 && first.kind_of?(Array) ? first.condense : self
    end
  end
end

# @private
class Array
  include Chicago::ArrayExtensions
end
