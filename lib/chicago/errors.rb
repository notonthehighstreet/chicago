module Chicago
  # Error raised when a fact or a dimension is defined more than once
  # in a StarSchema
  class DuplicateTableError < StandardError ; end

  # Error raised when a fact, dimension or column is referenced, but
  # is not defined in a Star Schema.
  class MissingDefinitionError < StandardError ; end

  # Error raised when a Null record is defined without an id field.
  #
  # Null records must have explicit ids to avoid overwriting extracted
  # data unintentionally.
  class UnsafeNullRecordError < StandardError ; end
end
